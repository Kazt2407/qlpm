class ReportsController < ApplicationController
  require "csv"

  before_action :require_admin!

  def index
    @month = params[:month]&.to_date || Date.current.beginning_of_month
    month_range = @month.beginning_of_month..@month.end_of_month

    @total_borrows      = Borrow.where(starts_at: month_range).count
    @on_time_return_pct = calculate_on_time_pct(month_range)
    @rooms_in_use       = Asset.where(asset_type: "room", status: "in_use").count
    @under_repair       = Asset.where(status: %w[broken maintenance]).count

    @monthly_trend = 6.downto(0).map do |offset|
      m = offset.months.ago.beginning_of_month.to_date
      range = m.beginning_of_month..m.end_of_month
      { month: I18n.l(m, format: "%m/%Y"), count: Borrow.where(starts_at: range).count }
    end

    @assets_by_type = Asset::ASSET_TYPES.map do |type|
      total = Asset.where(asset_type: type).count
      active = Asset.where(asset_type: type, status: "active").count
      pct = total.positive? ? (active.to_f / total * 100).round : 0
      { type: type, total: total, active: active, pct: pct }
    end

    @top_borrowers = Borrow
      .group(:borrower_name, :borrower_group)
      .order("count_all DESC")
      .limit(AppSettings.report_top_borrowers_limit)
      .count

    @attention_assets = Asset.where(status: %w[broken maintenance inactive]).order(updated_at: :desc).limit(AppSettings.report_attention_assets_limit)
    @borrow_sources = Borrow.group(:borrow_source).count
    @borrower_mix = Borrow.group(:borrower_type).count

    @available_months = (0...AppSettings.report_months_lookback).map { |i| i.months.ago.to_date.beginning_of_month }.reverse
  end

  def export
    month = params[:month]&.to_date || Date.current.beginning_of_month
    range = month.beginning_of_month..month.end_of_month
    borrows = Borrow.includes(:asset, :created_by, :approved_by).where(starts_at: range).order(:starts_at)

    csv = CSV.generate(headers: true) do |out|
      out << [
        "Borrow ID", "Asset Code", "Asset Name", "Borrower",
        "Borrower Type", "Source", "Workflow", "Starts At",
        "Ends At", "Returned At", "Created By", "Approved By"
      ]

      borrows.each do |borrow|
        out << [
          borrow.id,
          borrow.asset&.code,
          borrow.asset&.name,
          borrow.borrower_name,
          borrow.borrower_type,
          borrow.borrow_source,
          borrow.workflow_state,
          borrow.starts_at,
          borrow.ends_at,
          borrow.returned_at,
          borrow.created_by&.email,
          borrow.approved_by&.email
        ]
      end
    end

    send_data csv,
              filename: "reports-#{month.strftime('%Y-%m')}.csv",
              type: "text/csv; charset=utf-8"
  end

  private

  def calculate_on_time_pct(range)
    total    = Borrow.returned.where(starts_at: range).count
    on_time  = Borrow.returned.where(starts_at: range)
                     .where("returned_at <= ends_at").count
    return 0 if total.zero?
    (on_time.to_f / total * 100).round(1)
  end
end
