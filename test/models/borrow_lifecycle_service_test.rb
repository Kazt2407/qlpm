require "test_helper"

class BorrowLifecycleServiceTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(
      full_name: "Admin",
      email: "admin-test@example.com",
      role: "admin",
      user_type: "admin",
      password: "password123"
    )
    @teacher = User.create!(
      full_name: "Teacher",
      email: "teacher-test@example.com",
      role: "user",
      user_type: "teacher",
      password: "password123"
    )
    @room = Room.create!(code: "RM-1", name: "Room 1", room_type: "computer_room", status: "active")
    @asset = Asset.create!(
      code: "PC-01",
      name: "PC 01",
      asset_type: "computer",
      category: "computer",
      room: @room,
      status: "active"
    )
  end

  test "approve transitions and syncs asset status" do
    borrow = Borrow.create!(
      asset: @asset,
      borrow_source: "manual_request",
      borrower_type: "teacher",
      borrower_name: "Teacher",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      workflow_state: "pending"
    )

    BorrowLifecycleService.approve!(borrow, @admin)

    assert_equal "approved", borrow.reload.workflow_state
    assert_not_nil borrow.approved_at
    assert_equal @admin, borrow.approved_by
    assert_equal "borrowed", @asset.reload.status
  end

  test "mark returned resets asset state" do
    borrow = Borrow.create!(
      asset: @asset,
      borrow_source: "manual_request",
      borrower_type: "teacher",
      borrower_name: "Teacher",
      starts_at: 1.hour.ago,
      ends_at: 1.hour.from_now,
      workflow_state: "approved"
    )
    BorrowLifecycleService.sync_asset_status!(@asset)
    assert_equal "borrowed", @asset.reload.status

    BorrowLifecycleService.mark_returned!(borrow)

    assert_equal "returned", borrow.reload.workflow_state
    assert_not_nil borrow.returned_at
    assert_equal "active", @asset.reload.status
  end

  test "apply defaults for non-admin makes pending manual request" do
    borrow = Borrow.new(
      asset: @asset,
      borrow_source: "imported_schedule",
      borrower_type: "system",
      borrower_name: "X",
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now
    )

    BorrowLifecycleService.apply_defaults!(borrow, @teacher)

    assert_equal @teacher, borrow.created_by
    assert_equal "manual_request", borrow.borrow_source
    assert_equal "pending", borrow.workflow_state
    assert_equal @teacher.full_name, borrow.borrower_name
  end
end
