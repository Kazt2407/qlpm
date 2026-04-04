class ApplicationController < ActionController::Base
  before_action :require_login
  before_action :set_sidebar_counts
  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    return if current_user.present?

    redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
  end

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: "Bạn không có quyền truy cập khu vực quản trị."
  end

  def set_sidebar_counts
    @sidebar_assets = Asset.count
    @sidebar_rooms = Room.count
    @sidebar_active = Asset.where(status: "active").count
    @sidebar_open_borrows = Borrow.active.count
  end
end
