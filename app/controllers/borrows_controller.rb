class BorrowsController < ApplicationController
  before_action :set_borrow, only: %i[
    show edit update destroy confirm_return send_reminder approve reject cancel
  ]
  before_action :require_request_submission_access!, only: %i[new create]
  before_action :require_borrow_visibility!, only: %i[show]
  before_action :require_admin!, only: %i[edit update destroy cancel send_reminder]
  before_action :require_borrow_reviewer!, only: %i[confirm_return approve reject]

  SORT_OPTIONS = {
    "starts_desc" => { starts_at: :desc },
    "starts_asc" => { starts_at: :asc },
    "ends_desc" => { ends_at: :desc },
    "ends_asc" => { ends_at: :asc },
    "updated_desc" => { updated_at: :desc }
  }.freeze

  def index
    base_scope = can_review_borrows? ? Borrow.all : Borrow.where(created_by: current_user)

    @borrows = base_scope.includes(:asset, :created_by, :approved_by)
    @borrows = apply_tab(@borrows)
    @borrows = @borrows.with_state(params[:state])
    @borrows = @borrows.with_source(params[:source])
    @borrows = @borrows.for_asset(params[:asset_id])
    @borrows = @borrows.borrower_like(params[:borrower_query])
    @borrows = @borrows.starting_from(parse_datetime_param(params[:from]))
    @borrows = @borrows.ending_before(parse_datetime_param(params[:to]))
    @borrows = @borrows.order(sort_option)

    @borrows, @page, @per_page, @total_pages, @total_count = paginate_scope(@borrows)

    @total_borrowing = base_scope.active.count
    @total_returned  = base_scope.returned.this_month.count
    @total_overdue   = base_scope.overdue.count
    @total_pending   = base_scope.where(workflow_state: "pending").count
    @total_approved  = base_scope.where(workflow_state: "approved").count

    @active_tab = params[:tab].presence || "all"
    @assets_for_filter = Asset.order(:asset_type, :code)
  end

  def new
    @borrow = Borrow.new(
      starts_at: Time.current.change(min: 0),
      ends_at: AppSettings.borrow_default_duration_minutes.minutes.from_now.change(min: 0),
      borrow_source: "manual_request",
      workflow_state: "pending",
      borrower_type: inferred_borrower_type,
      asset_id: params[:asset_id]
    )

    BorrowLifecycleService.apply_defaults!(@borrow, current_user) unless can_manage_system?
    load_form_data
  end

  def create
    @borrow = Borrow.new(borrow_params)
    BorrowLifecycleService.apply_defaults!(@borrow, current_user)

    if @borrow.save
      BorrowLifecycleService.sync_asset_status!(@borrow.asset)
      redirect_to borrows_path, notice: "Phiếu mượn đã được tạo thành công."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit
    load_form_data
  end

  def update
    previous_asset = @borrow.asset
    @borrow.assign_attributes(borrow_params)
    BorrowLifecycleService.apply_defaults!(@borrow, current_user)

    if @borrow.save
      BorrowLifecycleService.sync_asset_status!(previous_asset) if previous_asset != @borrow.asset
      BorrowLifecycleService.sync_asset_status!(@borrow.asset)
      redirect_to borrows_path, notice: "Cập nhật phiếu mượn thành công."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    asset = @borrow.asset
    @borrow.destroy
    BorrowLifecycleService.sync_asset_status!(asset)
    redirect_to borrows_path, notice: "Đã xóa phiếu mượn."
  end

  def confirm_return
    BorrowLifecycleService.mark_returned!(@borrow)
    redirect_to borrows_path, notice: "Đã xác nhận trả thiết bị."
  rescue StandardError => e
    redirect_to borrows_path, alert: "Lỗi: #{e.message}"
  end

  def approve
    if @borrow.can_approve?
      BorrowLifecycleService.approve!(@borrow, current_user)
      redirect_to borrows_path, notice: "Đã duyệt phiếu mượn."
    else
      redirect_to borrows_path, alert: "Phiếu không ở trạng thái chờ duyệt."
    end
  end

  def reject
    if @borrow.can_reject?
      BorrowLifecycleService.reject!(@borrow)
      redirect_to borrows_path, notice: "Đã từ chối phiếu mượn."
    else
      redirect_to borrows_path, alert: "Không thể từ chối phiếu ở trạng thái hiện tại."
    end
  end

  def cancel
    if @borrow.can_cancel?
      BorrowLifecycleService.cancel!(@borrow)
      redirect_to borrows_path, notice: "Đã hủy phiếu mượn."
    else
      redirect_to borrows_path, alert: "Không thể hủy phiếu ở trạng thái hiện tại."
    end
  end

  def send_reminder
    BorrowLifecycleService.remind!(@borrow, channel: "email")
    redirect_to borrows_path, notice: "Đã gửi nhắc nhở qua thư điện tử đến #{@borrow.borrower_name}."
  end

  private

  def set_borrow
    @borrow = Borrow.find(params[:id])
  end

  def borrow_params
    allowed = %i[asset_id starts_at ends_at purpose notes]
    if can_manage_system?
      allowed += %i[
        borrow_source borrower_type borrower_name borrower_identifier
        borrower_group workflow_state approved_by_id
      ]
    end

    params.require(:borrow).permit(*allowed)
  end

  def load_form_data
    @available_assets = Asset.where.not(status: "inactive").or(Asset.where(id: @borrow.asset_id)).order(:asset_type, :code)
    @approvers = User.active.where(role: %w[admin approver]).order(:full_name)
  end

  def inferred_borrower_type
    current_user.user_type.in?(%w[teacher student]) ? current_user.user_type : "teacher"
  end

  def require_borrow_visibility!
    return if can_review_borrows? || @borrow.created_by == current_user

    redirect_to borrows_path, alert: "Bạn không có quyền xem phiếu này."
  end

  def apply_tab(scope)
    case params[:tab]
    when "active" then scope.active
    when "returned" then scope.returned
    when "overdue" then scope.overdue
    else scope
    end
  end

  def sort_option
    SORT_OPTIONS.fetch(params[:sort], SORT_OPTIONS["starts_desc"])
  end
end
