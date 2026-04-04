class DevicesController < ApplicationController
  PER_PAGE = 15

  before_action :set_device, only: %i[show edit update destroy update_status]

  def index
    @devices = Device.all
    @devices = @devices.search(params[:q])                    if params[:q].present?
    @devices = @devices.by_type(params[:device_type])         if params[:device_type].present?
    @devices = @devices.by_room(params[:room])                if params[:room].present?
    @devices = @devices.where(status: params[:status])        if params[:status].present?

    ordered_devices = @devices.order(created_at: :desc)
    @total_count = ordered_devices.count
    @total_pages = [(@total_count.to_f / PER_PAGE).ceil, 1].max
    @current_page = params.fetch(:page, 1).to_i
    @current_page = 1 if @current_page < 1
    @current_page = @total_pages if @current_page > @total_pages
    offset = (@current_page - 1) * PER_PAGE

    @devices = ordered_devices.limit(PER_PAGE).offset(offset)
  end

  def show
    @borrow_history = @device.borrows.order(borrowed_at: :desc)
  end

  def new
    @device = Device.new
  end

  def create
    @device = Device.new(device_params)
    if @device.save
      redirect_to devices_path, notice: "Thiết bị đã được thêm thành công."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @device.update(device_params)
      redirect_to device_path(@device), notice: "Cập nhật thiết bị thành công."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @device.destroy
    redirect_to devices_path, notice: "Đã xóa thiết bị."
  end

  def update_status
    if @device.update(status: params[:status])
      redirect_back fallback_location: devices_path, notice: "Cập nhật trạng thái thành công."
    else
      redirect_back fallback_location: devices_path, alert: "Không thể cập nhật trạng thái."
    end
  end

  private

  def set_device
    @device = Device.find(params[:id])
  end

  def device_params
    params.require(:device).permit(
      :code, :name, :device_type, :room, :brand, :device_name,
      :imported_at, :warranty_until, :status, :notes,
      :cpu, :ram, :storage, :os, :ip_address, :desk_number
    )
  end
end
