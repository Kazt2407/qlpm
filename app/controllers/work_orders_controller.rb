class WorkOrdersController < ApplicationController
  before_action :require_admin!, except: %i[new create show]
  before_action :require_request_submission_access!, only: %i[new create]
  before_action :set_work_order, only: %i[show edit update destroy]

  def index
    @work_orders = WorkOrder.includes(:asset, :reported_by, :assigned_to).recent
    @work_orders = @work_orders.with_status(params[:status])
    @work_orders = @work_orders.with_priority(params[:priority])
    @work_orders = @work_orders.for_asset(params[:asset_id])
    @work_orders, @page, @per_page, @total_pages, @total_count = paginate_scope(@work_orders)
    @assets_for_filter = Asset.order(:code)
  end

  def show
    return if can_manage_system? || @work_order.reported_by == current_user

    redirect_to borrows_path, alert: "Bạn không có quyền xem phiếu bảo trì này."
  end

  def new
    @work_order = WorkOrder.new(asset_id: params[:asset_id], priority: "normal", status: "open")
    load_form_data
  end

  def create
    @work_order = WorkOrder.new(work_order_params)
    @work_order.reported_by = current_user
    @work_order.status = "open" unless can_manage_system?

    if @work_order.save
      sync_asset_status
      redirect_to @work_order, notice: "Đã ghi nhận yêu cầu bảo trì."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    if @work_order.update(work_order_params)
      sync_asset_status
      redirect_to work_orders_path, notice: "Đã cập nhật yêu cầu bảo trì."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @work_order.destroy
    redirect_to work_orders_path, notice: "Đã xóa yêu cầu bảo trì."
  end

  private

  def set_work_order
    @work_order = WorkOrder.find(params[:id])
  end

  def load_form_data
    @assets = Asset.order(:code)
    @assignees = User.active.where(role: %w[admin approver]).order(:full_name)
  end

  def work_order_params
    allowed = %i[asset_id title description priority]
    allowed += %i[status assigned_to_id due_on cost resolution_notes] if can_manage_system?
    params.require(:work_order).permit(*allowed)
  end

  def sync_asset_status
    return unless @work_order.status.in?(%w[open in_progress resolved])

    if @work_order.status == "resolved"
      if @work_order.asset.work_orders.open.where.not(id: @work_order.id).none? && @work_order.asset.status == "maintenance"
        @work_order.asset.update!(status: "active")
      end
      BorrowLifecycleService.sync_asset_status!(@work_order.asset)
    elsif @work_order.asset.status == "active"
      @work_order.asset.update!(status: "maintenance")
    end
  end
end
