require "test_helper"

class BorrowsWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      full_name: "Admin",
      email: "admin-flow@example.com",
      role: "admin",
      user_type: "admin",
      password: "password123"
    )
    @teacher = User.create!(
      full_name: "Teacher",
      email: "teacher-flow@example.com",
      role: "user",
      user_type: "teacher",
      password: "password123"
    )
    @approver = User.create!(
      full_name: "Approver",
      email: "approver-flow@example.com",
      role: "approver",
      user_type: "teacher",
      password: "password123"
    )
    room = Room.create!(code: "RM-WF", name: "Room WF", room_type: "computer_room", status: "active")
    @asset = Asset.create!(
      code: "AS-WF",
      name: "Asset WF",
      asset_type: "computer",
      category: "computer",
      room: room,
      status: "active"
    )
    @borrow = Borrow.create!(
      asset: @asset,
      created_by: @teacher,
      borrow_source: "manual_request",
      borrower_type: "teacher",
      borrower_name: @teacher.full_name,
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      workflow_state: "pending"
    )
    ActionMailer::Base.deliveries.clear
  end

  test "approver can approve and reject borrow via endpoints" do
    login_as(@approver)

    patch approve_borrow_path(@borrow)
    assert_redirected_to borrows_path
    assert_equal "approved", @borrow.reload.workflow_state

    patch reject_borrow_path(@borrow)
    assert_redirected_to borrows_path
    assert_equal "rejected", @borrow.reload.workflow_state
  end

  test "teacher cannot access admin-only users area" do
    login_as(@teacher)

    get users_path
    assert_redirected_to borrows_path
  end

  test "admin can send borrow reminder through mail" do
    @borrow.update!(workflow_state: "approved", starts_at: 2.hours.ago, ends_at: 1.hour.ago)
    login_as(@admin)

    assert_difference("ActionMailer::Base.deliveries.size", 1) do
      post send_reminder_borrow_path(@borrow)
    end

    assert_redirected_to borrows_path
    assert_not_nil @borrow.reload.reminded_at
    assert_equal "email", @borrow.reminder_channel

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@teacher.email], mail.to
    assert_match "Nhắc trả thiết bị #{@asset.code}", mail.subject
    assert_match @borrow.borrower_name, mail.body.encoded
  end
end
