class SessionsController < ApplicationController
  skip_before_action :require_login
  layout false, only: %i[new]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Đăng nhập thành công."
    else
      flash.now[:alert] = "Email hoặc mật khẩu không đúng."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Đã đăng xuất."
  end
end
