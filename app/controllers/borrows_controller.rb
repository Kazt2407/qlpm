class BorrowsController < ApplicationController
  before_action :set_borrow, only: %i[show edit update destroy confirm_return send_reminder]

  def index
    @borrows = Borrow.includes(:device)
    @borrows = case params[:tab]
               when "borrowing" then @borrows.borrowing
               when "returned"  then @borrows.returned
               when "overdue"   then @borrows.overdue
               else @borrows
               end
    @borrows = @borrows.recent

    @total_borrowing = Borrow.borrowing.count
    @total_returned  = Borrow.returned.this_month.count
    @total_overdue   = Borrow.overdue.count
    @active_tab      = params[:tab] || "all"
  end

  def new
    @borrow = Borrow.new(borrowed_at: Date.today)
    @available_devices = Device.active
  end

  def create
    @borrow = Borrow.new(borrow_params)
    if @borrow.save
      @borrow.device.update!(status: "borrowed")
      redirect_to borrows_path, notice: "Phiếu mượn đã được tạo thành công."
    else
      @available_devices = Device.active
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit
    @available_devices = Device.active.or(Device.where(id: @borrow.device_id))
  end

  def update
    previous_device = @borrow.device

    if @borrow.update(borrow_params)
      previous_device.update!(status: "active") if previous_device != @borrow.device && previous_device.active_borrow.blank?
      @borrow.device.update!(status: "borrowed") if @borrow.returned_at.nil?
      redirect_to borrows_path, notice: "Cập nhật phiếu mượn thành công."
    else
      @available_devices = Device.active.or(Device.where(id: @borrow.device_id))
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    device = @borrow.device
    @borrow.destroy
    device.update!(status: "active") if device.active_borrow.blank?
    redirect_to borrows_path, notice: "Đã xóa phiếu mượn."
  end

  def confirm_return
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
    params.require(:borrow).permit(
      :device_id, :borrower_name, :borrower_class,
      :borrowed_at, :due_at, :purpose, :notes
    )
  end
end
