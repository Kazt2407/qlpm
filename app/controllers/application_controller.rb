class ApplicationController < ActionController::Base
  before_action :set_sidebar_counts

  private

  def set_sidebar_counts
    @sidebar_total    = Device.count
    @sidebar_active   = Device.active.count
    @sidebar_borrowed = Device.borrowed.count
    @sidebar_broken   = Device.broken.count
  end
end
