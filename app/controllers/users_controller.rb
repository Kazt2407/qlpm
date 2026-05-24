class UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[edit update destroy toggle_active reset_password]

  SORT_OPTIONS = {
    "name_asc" => { full_name: :asc },
    "name_desc" => { full_name: :desc },
    "created_desc" => { created_at: :desc },
    "updated_desc" => { updated_at: :desc }
  }.freeze

  def index
    @users = User.order(sort_option)
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.where(user_type: params[:user_type]) if params[:user_type].present?
    @users = @users.where(active: ActiveModel::Type::Boolean.new.cast(params[:active])) if params[:active].present?

    if params[:q].present?
      @users = @users.where("full_name LIKE :q OR email LIKE :q OR identifier LIKE :q", q: "%#{params[:q]}%")
    end

    @users, @page, @per_page, @total_pages, @total_count = paginate_scope(@users)
  end

  def new
    @user = User.new(role: "user", user_type: "teacher", active: true)
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: "Đã tạo người dùng mới."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to users_path, notice: "Đã cập nhật người dùng."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to users_path, alert: "Không thể xóa tài khoản đang đăng nhập."
      return
    end

    @user.destroy
    redirect_to users_path, notice: "Đã xóa người dùng."
  end

  def toggle_active
    if @user == current_user
      redirect_to users_path, alert: "Không thể tự vô hiệu hóa tài khoản hiện tại."
      return
    end

    @user.update!(active: !@user.active)
    message = @user.active ? "Đã kích hoạt tài khoản." : "Đã vô hiệu hóa tài khoản."
    redirect_to users_path, notice: message
  end

  def reset_password
    temporary_password = SecureRandom.alphanumeric(10)
    @user.update!(password: temporary_password)
    redirect_to users_path, notice: "Đã đặt lại mật khẩu cho #{@user.email}. Mật khẩu tạm: #{temporary_password}"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    permitted = %i[full_name email role user_type identifier department active]
    permitted += %i[password password_confirmation] if params.dig(:user, :password).present?
    params.require(:user).permit(*permitted)
  end

  def sort_option
    SORT_OPTIONS.fetch(params[:sort], SORT_OPTIONS["name_asc"])
  end
end
