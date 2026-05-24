class AssetsController < ApplicationController
  before_action :set_asset, only: %i[show edit update destroy]
  before_action :require_admin!

  SORT_OPTIONS = {
    "code_asc" => { code: :asc },
    "code_desc" => { code: :desc },
    "name_asc" => { name: :asc },
    "name_desc" => { name: :desc },
    "updated_desc" => { updated_at: :desc }
  }.freeze

  def index
    @assets = Asset.includes(:room, :parent)
    @assets = @assets.search(params[:q])
    @assets = @assets.where(asset_type: params[:asset_type]) if params[:asset_type].present?
    @assets = @assets.where(category: params[:category]) if params[:category].present?
    @assets = @assets.where(status: params[:status]) if params[:status].present?
    @assets = @assets.where(room_id: params[:room_id]) if params[:room_id].present?
    @assets = @assets.order(sort_option)
    @assets, @page, @per_page, @total_pages, @total_count = paginate_scope(@assets)

    @asset_types = Asset::ASSET_TYPES
    @categories = Asset::CATEGORIES
    @rooms = Room.order(:name)
  end

  def show
    @borrow_history = @asset.borrows.includes(:created_by, :approved_by).recent
    @child_assets = @asset.children.includes(:room).order(:code)
  end

  def new
    @asset = Asset.new(asset_type: params[:asset_type] || "device", status: "active")
    load_form_data
  end

  def create
    @asset = Asset.new(asset_params)
    if @asset.save
      redirect_to asset_path(@asset), notice: "Đã tạo đối tượng thành công."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    if @asset.update(asset_params)
      redirect_to asset_path(@asset), notice: "Đã cập nhật đối tượng."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @asset.destroy
    redirect_to assets_path, notice: "Đã xóa đối tượng."
  end

  private

  def set_asset
    @asset = Asset.find(params[:id])
  end

  def load_form_data
    @rooms = Room.order(:name)
    @parent_assets = Asset.where.not(id: @asset.id).order(:code)
  end

  def asset_params
    params.require(:asset).permit(
      :code, :name, :asset_type, :category, :room_id, :parent_id, :status,
      :brand, :model_code, :serial_number, :imported_at, :warranty_until,
      :desk_number, :cpu, :ram, :storage, :os, :ip_address, :notes
    )
  end

  def sort_option
    SORT_OPTIONS.fetch(params[:sort], { asset_type: :asc, code: :asc })
  end
end
