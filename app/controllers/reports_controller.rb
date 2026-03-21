class ReportsController < ApplicationController
  def index
    # Date range filter
    @month = params[:month]&.to_date || Date.current.beginning_of_month
    month_range = @month.beginning_of_month..@month.end_of_month

    # KPI
    @total_borrows      = Borrow.where(borrowed_at: month_range).count
    @on_time_return_pct = calculate_on_time_pct(month_range)
    @new_broken         = Device.where(status: "broken").count
    @under_repair       = Device.maintenance.count

    # Monthly borrow trend (last 7 months)
    @monthly_trend = (6.months.ago.to_date..Date.today).select { |d| d.day == 1 }.map do |m|
      range = m.beginning_of_month..m.end_of_month
      { month: I18n.l(m, format: "%m/%Y"), count: Borrow.where(borrowed_at: range).count }
    end

    # Devices by type
    @devices_by_type = Device::TYPES.map do |type|
      total = Device.where(device_type: type).count
      active = Device.where(device_type: type, status: "active").count
      pct = total.positive? ? (active.to_f / total * 100).round : 0
      { type: type, total: total, active: active, pct: pct }
    end

    # Top borrowers
    @top_borrowers = Borrow
      .group(:borrower_name, :borrower_class)
      .order("count_all DESC")
      .limit(5)
      .count

    # Broken / maintenance devices
    @broken_devices = Device.where(status: %w[broken maintenance]).order(updated_at: :desc)

    # Available months for filter
    @available_months = (0..11).map { |i| i.months.ago.to_date.beginning_of_month }.reverse
  end

  def export
    # Placeholder for PDF/Excel export
    redirect_to reports_path, notice: "Tính năng xuất báo cáo đang được phát triển."
  end

  private

  def calculate_on_time_pct(range)
    total    = Borrow.returned.where(borrowed_at: range).count
    on_time  = Borrow.returned.where(borrowed_at: range)
                     .where("returned_at <= due_at").count
    return 0 if total.zero?
    (on_time.to_f / total * 100).round(1)
  end
end
