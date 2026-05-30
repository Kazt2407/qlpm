class SchedulesController < ApplicationController
  before_action :require_borrow_reviewer!

  def show
    @date = parse_date_param(params[:date]) || Date.current
    @room_id = params[:room_id].presence
    @rooms = Room.order(:name)
    @days = (@date.beginning_of_week(:monday)..@date.end_of_week(:monday)).to_a

    scope = Borrow.includes(asset: :room).where(starts_at: @days.first.beginning_of_day..@days.last.end_of_day)
    scope = scope.joins(:asset).where(assets: { room_id: @room_id }) if @room_id
    @borrows_by_day = scope.order(:starts_at).group_by { |borrow| borrow.starts_at.to_date }
  end

  private

  def parse_date_param(value)
    return nil if value.blank?

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
