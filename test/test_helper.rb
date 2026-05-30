ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

module ActiveSupport
  class TestCase
    # Minitest setup is intentionally lightweight; database isolation is handled by Rails.
  end
end

class ActionDispatch::IntegrationTest
  private

  def login_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end
end
