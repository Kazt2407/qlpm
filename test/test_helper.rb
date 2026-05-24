ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Keep tests single-process for SQLite stability in local dev.
  end
end

class ActionDispatch::IntegrationTest
  private

  def login_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end
end
