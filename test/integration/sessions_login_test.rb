require "test_helper"

class SessionsLoginTest < ActionDispatch::IntegrationTest
  setup do
    @teacher = User.create!(
      full_name: "Login User",
      email: "login-user@example.com",
      role: "user",
      user_type: "teacher",
      password: "password123",
      active: true
    )
    @approver = User.create!(
      full_name: "Borrow Approver",
      email: "approver-login@example.com",
      role: "approver",
      user_type: "teacher",
      password: "password123",
      active: true
    )
    @admin = User.create!(
      full_name: "System Admin",
      email: "admin-login@example.com",
      role: "admin",
      user_type: "admin",
      password: "password123",
      active: true
    )
  end

  test "failed login renders login page without crashing" do
    post login_path, params: { email: @teacher.email, password: "wrong-password" }

    assert_response :unprocessable_entity
    assert_match "Thư điện tử hoặc mật khẩu không đúng.", @response.body
  end

  test "teacher login redirects to borrow list" do
    post login_path, params: { email: @teacher.email, password: "password123" }

    assert_redirected_to borrows_path
  end

  test "approver login redirects to borrow list" do
    post login_path, params: { email: @approver.email, password: "password123" }

    assert_redirected_to borrows_path
  end

  test "admin login redirects to dashboard" do
    post login_path, params: { email: @admin.email, password: "password123" }

    assert_redirected_to root_path
  end
end
