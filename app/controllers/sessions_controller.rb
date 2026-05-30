class SessionsController < ApplicationController
  skip_before_action :require_login
  layout false, only: %i[new create]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password]) && user.active?
      session[:user_id] = user.id
      redirect_to after_login_path_for(user), notice: "Đăng nhập thành công."
    elsif user.present? && !user.active?
      flash.now[:alert] = "Tài khoản đã bị vô hiệu hóa."
      render :new, status: :unprocessable_entity
    else
      flash.now[:alert] = "Thư điện tử hoặc mật khẩu không đúng."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Đã đăng xuất."
  end

  private

  def after_login_path_for(user)
    user.can_manage_system? ? root_path : borrows_path
  end
end
