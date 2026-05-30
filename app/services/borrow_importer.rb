require "csv"

class BorrowImporter
  Preview = Struct.new(:rows, keyword_init: true) do
    def valid_rows
      rows.select(&:valid?)
    end

    def invalid_rows
      rows.reject(&:valid?)
    end
  end

  Row = Struct.new(:row_number, :attributes, :errors, keyword_init: true) do
    def valid?
      errors.empty?
    end
  end

  Result = Struct.new(:created_count, :import_batch, keyword_init: true)

  REQUIRED_HEADERS = %w[asset_code borrower_name starts_at ends_at].freeze

  def self.preview(raw_csv, actor)
    new(raw_csv, actor).preview
  end

  def self.commit(rows, actor)
    import_batch = "csv-#{Time.current.strftime('%Y%m%d%H%M%S')}"
    created_count = 0

    Borrow.transaction do
      rows.each_with_index do |attrs, index|
        borrow = Borrow.new(normalize_attrs(attrs))
        borrow.import_batch = import_batch
        borrow.import_row_number = index + 1
        BorrowLifecycleService.apply_defaults!(borrow, actor)
        borrow.borrow_source = "imported_schedule"
        borrow.workflow_state = "approved"
        borrow.approved_by ||= actor
        borrow.approved_at ||= Time.current
        borrow.save!
        BorrowLifecycleService.sync_asset_status!(borrow.asset)
        created_count += 1
      end
    end

    Result.new(created_count: created_count, import_batch: import_batch)
  end

  def initialize(raw_csv, actor)
    @raw_csv = raw_csv
    @actor = actor
  end

  def preview
    csv = CSV.parse(@raw_csv, headers: true)
    missing_headers = REQUIRED_HEADERS - csv.headers.to_a.map(&:to_s)

    rows = csv.each_with_index.map do |row, index|
      build_row(row, index + 2, missing_headers)
    end

    Preview.new(rows: rows)
  end

  private

  def self.normalize_attrs(attrs)
    attrs.symbolize_keys.tap do |normalized|
      normalized[:starts_at] = Time.zone.parse(normalized[:starts_at].to_s) if normalized[:starts_at].present?
      normalized[:ends_at] = Time.zone.parse(normalized[:ends_at].to_s) if normalized[:ends_at].present?
      normalized[:approved_at] = Time.zone.parse(normalized[:approved_at].to_s) if normalized[:approved_at].present?
    end
  end

  def build_row(row, row_number, missing_headers)
    errors = []
    errors << "Thiếu cột: #{missing_headers.join(', ')}" if missing_headers.any?

    asset = Asset.find_by(code: row["asset_code"].to_s.strip)
    errors << "Không tìm thấy đối tượng theo cột asset_code" unless asset

    starts_at = parse_time(row["starts_at"])
    ends_at = parse_time(row["ends_at"])
    errors << "Thời gian bắt đầu không hợp lệ (starts_at)" unless starts_at
    errors << "Thời gian kết thúc không hợp lệ (ends_at)" unless ends_at

    attrs = {
      asset_id: asset&.id,
      borrow_source: "imported_schedule",
      borrower_type: row["borrower_type"].presence || "system",
      borrower_name: row["borrower_name"].presence || "Hệ thống xếp lịch",
      borrower_identifier: row["borrower_identifier"].presence,
      borrower_group: row["borrower_group"].presence,
      starts_at: starts_at&.iso8601,
      ends_at: ends_at&.iso8601,
      workflow_state: "approved",
      purpose: row["purpose"].presence,
      notes: row["notes"].presence,
      approved_by_id: @actor.id,
      approved_at: Time.current.iso8601
    }

    borrow = Borrow.new(self.class.normalize_attrs(attrs))
    unless borrow.valid?
      errors.concat(borrow.errors.full_messages)
    end

    Row.new(row_number: row_number, attributes: attrs, errors: errors.uniq)
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
