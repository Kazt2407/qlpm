class DashboardController < ApplicationController
  def index
    # Stat cards
    @total_devices    = Device.count
    @active_devices   = Device.active.count
    @borrowed_devices = Device.borrowed.count
    @broken_devices   = Device.broken.count

    # Bar chart: devices per room
    @devices_by_room = Device::ROOMS.map do |room|
      { room: room, count: Device.by_room(room).count }
    end

    # Donut chart data
    @status_counts = {
      active:      @active_devices,
      borrowed:    @borrowed_devices,
      broken:      @broken_devices,
      maintenance: Device.maintenance.count
    }
    @active_pct = @total_devices.positive? ? (@active_devices.to_f / @total_devices * 100).round(1) : 0

    # Recent activity (last 10 borrow records)
    @recent_borrows = Borrow.includes(:device).recent.limit(10)
  end
end
