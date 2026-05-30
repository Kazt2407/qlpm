require "test_helper"

class ReportsHardeningTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      full_name: "Admin Reports",
      email: "admin-reports@example.com",
      role: "admin",
      user_type: "admin",
      password: "password123"
    )
  end

  test "invalid report month falls back without raising" do
    login_as(@admin)

    get reports_path, params: { month: "not-a-date" }
    assert_response :success
  end

  test "invalid report export month falls back without raising" do
    login_as(@admin)

    get export_reports_path, params: { month: "not-a-date" }
    assert_response :success
    assert_equal "text/csv", @response.media_type
  end
end
