class ReportsController < ApplicationController
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
      .limit(5)
      .count

    @attention_assets = Asset.where(status: %w[broken maintenance inactive]).order(updated_at: :desc).limit(5)
    @borrow_sources = Borrow.group(:borrow_source).count
    @borrower_mix = Borrow.group(:borrower_type).count

    @available_months = (0..11).map { |i| i.months.ago.to_date.beginning_of_month }.reverse
  end

  def export
    # Placeholder for PDF/Excel export
    redirect_to reports_path, notice: "Tính năng xuất báo cáo đang được phát triển."
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
