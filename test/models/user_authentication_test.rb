require "test_helper"
require "digest"

class UserAuthenticationTest < ActiveSupport::TestCase
  test "authenticates bcrypt users" do
    user = User.create!(
      full_name: "Bcrypt User",
      email: "bcrypt@example.com",
      role: "user",
      user_type: "teacher",
      password: "password123"
    )

    assert user.authenticate("password123")
    assert_not user.authenticate("wrongpass")
  end

  test "migrates legacy sha256 digest on successful login" do
    legacy_password = "legacyPass123"
    user = User.create!(
      full_name: "Legacy User",
      email: "legacy@example.com",
      role: "user",
      user_type: "teacher",
      password_digest: Digest::SHA256.hexdigest(legacy_password)
    )

    assert user.authenticate(legacy_password)
    assert user.password_digest.start_with?("$2")
    assert user.reload.authenticate(legacy_password)
  end
end
