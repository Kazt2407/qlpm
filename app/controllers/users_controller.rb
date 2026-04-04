class UsersController < ApplicationController
  before_action :require_admin!

  def index
    @users = User.order(:role, :user_type, :full_name)
  end
end
