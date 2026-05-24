class DashboardController < ApplicationController
  before_action :require_system_access!

  def index
    @total_assets = Asset.count
    @total_rooms = Room.count
    @active_assets = Asset.where(status: "active").count
    @borrowed_assets = Asset.where(status: %w[borrowed in_use]).count
    @maintenance_assets = Asset.where(status: %w[broken maintenance]).count
    @active_pct = @total_assets.positive? ? (@active_assets.to_f / @total_assets * 100).round(1) : 0

    @assets_by_room = Room.includes(:assets).order(:name).map do |room|
      {
        room: room.name,
        count: room.assets.count,
        active: room.assets.where(status: "active").count
      }
    end

    @borrow_mix = {
      student: Borrow.where(borrower_type: "student").count,
      teacher: Borrow.where(borrower_type: "teacher").count,
      system: Borrow.where(borrower_type: "system").count
    }

    scope = Borrow.includes(:asset).recent
    @recent_borrows = scope.limit(8)
  end
end
