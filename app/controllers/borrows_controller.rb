class BorrowsController < ApplicationController
  before_action :set_borrow, only: %i[show edit update destroy confirm_return send_reminder]

  def index
    @borrows = current_user.admin? ? Borrow.includes(:asset, :created_by) : Borrow.includes(:asset, :created_by).where(created_by: current_user)
    @borrows = case params[:tab]
               when "active" then @borrows.active
               when "returned"  then @borrows.returned
               when "overdue"   then @borrows.overdue
               else @borrows
               end
    @borrows = @borrows.recent

    base_scope = current_user.admin? ? Borrow.all : Borrow.where(created_by: current_user)
    @total_borrowing = base_scope.active.count
    @total_returned  = base_scope.returned.this_month.count
    @total_overdue   = base_scope.overdue.count
    @active_tab      = params[:tab] || "all"
  end

  def new
    @borrow = Borrow.new(
      starts_at: Time.current.change(min: 0),
      ends_at: 2.hours.from_now.change(min: 0),
      borrow_source: current_user.admin? ? "manual_request" : "manual_request",
      borrower_type: inferred_borrower_type
    )
    hydrate_borrower_from_user(@borrow) unless current_user.admin?
    load_form_data
  end

  def create
    @borrow = Borrow.new(borrow_params)
    apply_context_defaults(@borrow)
    if @borrow.save
      @borrow.asset.update!(status: @borrow.asset.asset_type == "room" ? "in_use" : "borrowed")
      redirect_to borrows_path, notice: "Phiếu mượn đã được tạo thành công."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit
    restrict_borrow_access!
    load_form_data
  end

  def update
    restrict_borrow_access!
    previous_asset = @borrow.asset

    if @borrow.update(borrow_params)
      apply_context_defaults(@borrow, persist: true)
      previous_asset.update!(status: "active") if previous_asset != @borrow.asset && previous_asset.borrows.active.blank?
      @borrow.asset.update!(status: @borrow.asset.asset_type == "room" ? "in_use" : "borrowed") if @borrow.returned_at.nil?
      redirect_to borrows_path, notice: "Cập nhật phiếu mượn thành công."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    restrict_borrow_access!
    asset = @borrow.asset
    @borrow.destroy
    asset.update!(status: "active") if asset.borrows.active.blank?
    redirect_to borrows_path, notice: "Đã xóa phiếu mượn."
  end

  def confirm_return
    restrict_borrow_access!
    @borrow.confirm_return!
    redirect_to borrows_path, notice: "Đã xác nhận trả thiết bị."
  rescue => e
    redirect_to borrows_path, alert: "Lỗi: #{e.message}"
  end

  def send_reminder
    # Placeholder: integrate email/SMS here
    redirect_to borrows_path, notice: "Đã gửi nhắc nhở đến #{@borrow.borrower_name}."
  end

  private

  def set_borrow
    @borrow = Borrow.find(params[:id])
  end

  def borrow_params
    allowed = %i[asset_id starts_at ends_at purpose notes]
    if current_user.admin?
      allowed += %i[borrow_source borrower_type borrower_name borrower_identifier borrower_group workflow_state approved_by_id]
    end

    params.require(:borrow).permit(*allowed)
  end

  def load_form_data
    @available_assets = Asset.where.not(status: "inactive").order(:asset_type, :code)
    @approvers = User.where(role: "admin").order(:full_name)
  end

  def apply_context_defaults(borrow, persist: false)
    unless current_user.admin?
      borrow.created_by = current_user
      hydrate_borrower_from_user(borrow)
      borrow.borrow_source = "manual_request"
      borrow.workflow_state = borrow.returned_at.present? ? "returned" : "active"
      borrow.approved_by ||= User.find_by(role: "admin")
    end

    if borrow.borrow_source == "imported_schedule"
      borrow.borrower_type = "system"
      borrow.borrower_name = "Hệ thống xếp lịch" if borrow.borrower_name.blank?
      borrow.workflow_state = "approved" if borrow.workflow_state.blank?
    end

    if current_user.admin? && borrow.borrow_source == "manual_request" && borrow.workflow_state.blank?
      borrow.workflow_state = borrow.returned_at.present? ? "returned" : "active"
    end

    borrow.save! if persist
  end

  def hydrate_borrower_from_user(borrow)
    borrow.borrower_type = inferred_borrower_type
    borrow.borrower_name = current_user.full_name
    borrow.borrower_identifier = current_user.identifier
    borrow.borrower_group = current_user.department
  end

  def inferred_borrower_type
    current_user.user_type.in?(%w[teacher student]) ? current_user.user_type : "teacher"
  end

  def restrict_borrow_access!
    return if current_user.admin? || @borrow.created_by == current_user

    redirect_to borrows_path, alert: "Bạn không có quyền thao tác với phiếu này."
  end
end
