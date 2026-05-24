class RoomsController < ApplicationController
  before_action :require_admin!
  before_action :set_room, only: %i[show edit update destroy]

  SORT_OPTIONS = {
    "name_asc" => { name: :asc },
    "name_desc" => { name: :desc },
    "code_asc" => { code: :asc },
    "updated_desc" => { updated_at: :desc }
  }.freeze

  def index
    @rooms = Room.order(sort_option)
    @rooms = @rooms.where(status: params[:status]) if params[:status].present?
    @rooms = @rooms.where(room_type: params[:room_type]) if params[:room_type].present?

    if params[:q].present?
      @rooms = @rooms.where("code LIKE :q OR name LIKE :q OR location LIKE :q", q: "%#{params[:q]}%")
    end

    @rooms, @page, @per_page, @total_pages, @total_count = paginate_scope(@rooms)
  end

  def show
    @assets = @room.assets.order(:asset_type, :code)
  end

  def new
    @room = Room.new(status: "active", room_type: "computer_room")
  end

  def create
    @room = Room.new(room_params)
    if @room.save
      redirect_to room_path(@room), notice: "Đã tạo phòng mới."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @room.update(room_params)
      redirect_to room_path(@room), notice: "Đã cập nhật phòng."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @room.destroy
    redirect_to rooms_path, notice: "Đã xóa phòng."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to rooms_path, alert: "Không thể xóa phòng vì vẫn còn đối tượng liên kết."
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:code, :name, :room_type, :status, :capacity, :location, :notes)
  end

  def sort_option
    SORT_OPTIONS.fetch(params[:sort], SORT_OPTIONS["name_asc"])
  end
end
