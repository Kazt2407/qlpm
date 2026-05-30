class ApplicationController < ActionController::Base
  before_action :require_login
  before_action :set_sidebar_counts
  helper_method :current_user, :can_review_borrows?, :can_manage_system?, :requester_user?

  private

  def current_user
    @current_user ||= User.active.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    if session[:user_id] && current_user.nil?
      reset_session
      redirect_to login_path, alert: "Tài khoản không tồn tại hoặc đã bị vô hiệu hóa."
      return
    end

    return if current_user.present?

    redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
  end

  def require_admin!
    return if can_manage_system?

    redirect_to borrows_path, alert: "Bạn không có quyền truy cập khu vực quản trị."
  end

  def require_borrow_reviewer!
    return if can_review_borrows?

    redirect_to borrows_path, alert: "Bạn không có quyền duyệt phiếu mượn."
  end

  def require_request_submission_access!
    return if can_manage_system? || requester_user?

    redirect_to borrows_path, alert: "Bạn không có quyền tạo yêu cầu mượn."
  end

  def require_system_access!
    return if can_manage_system?

    redirect_to borrows_path, alert: "Bạn không có quyền truy cập dữ liệu hệ thống."
  end

  def set_sidebar_counts
    return unless current_user

    if can_manage_system?
      @sidebar_assets = Asset.count
      @sidebar_rooms = Room.count
      @sidebar_active = Asset.where(status: "active").count
      @sidebar_open_borrows = Borrow.active.count
      @sidebar_open_work_orders = WorkOrder.open.count if defined?(WorkOrder)
    elsif can_review_borrows?
      @sidebar_assets = "–"
      @sidebar_rooms = "–"
      @sidebar_active = Borrow.where(workflow_state: "pending").count
      @sidebar_open_borrows = Borrow.active.count
      @sidebar_open_work_orders = WorkOrder.open.count if defined?(WorkOrder)
    else
      my_scope = Borrow.where(created_by: current_user)
      @sidebar_assets = my_scope.count
      @sidebar_rooms = "–"
      @sidebar_active = my_scope.where(workflow_state: "pending").count
      @sidebar_open_borrows = my_scope.active.count
    end
  end

  def can_manage_system?
    current_user&.can_manage_system?
  end

  def can_review_borrows?
    current_user&.can_review_borrows?
  end

  def requester_user?
    current_user&.requester?
  end

  def paginate_scope(scope, per_page_default: nil, max_per_page: nil)
    page = params[:page].to_i
    page = 1 if page < 1

    per_page_default ||= AppSettings.pagination_default_per_page
    max_per_page ||= AppSettings.pagination_max_per_page

    per_page = params[:per_page].to_i
    per_page = per_page_default if per_page <= 0
    per_page = [per_page, max_per_page].min

    total_count = scope.count
    total_pages = (total_count.to_f / per_page).ceil
    total_pages = 1 if total_pages.zero?
    page = total_pages if page > total_pages

    paginated = scope.offset((page - 1) * per_page).limit(per_page)
    [paginated, page, per_page, total_pages, total_count]
  end

  def parse_datetime_param(value, fallback = nil)
    return fallback if value.blank?

    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    fallback
  end
end
