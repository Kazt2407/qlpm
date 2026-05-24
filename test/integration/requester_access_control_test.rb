require "test_helper"

class RequesterAccessControlTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      full_name: "Admin",
      email: "admin-access@example.com",
      role: "admin",
      user_type: "admin",
      password: "password123"
    )
    @approver = User.create!(
      full_name: "Approver",
      email: "approver-access@example.com",
      role: "approver",
      user_type: "teacher",
      password: "password123"
    )
    @teacher = User.create!(
      full_name: "Teacher A",
      email: "teacher-a@example.com",
      role: "user",
      user_type: "teacher",
      password: "password123",
      identifier: "GV-001",
      department: "Tổ Tin"
    )
    @other_teacher = User.create!(
      full_name: "Teacher B",
      email: "teacher-b@example.com",
      role: "user",
      user_type: "teacher",
      password: "password123"
    )

    room = Room.create!(code: "RM-AC", name: "Room AC", room_type: "computer_room", status: "active")
    @asset = Asset.create!(
      code: "AS-AC",
      name: "Asset AC",
      asset_type: "computer",
      category: "computer",
      room: room,
      status: "active"
    )

    @own_borrow = Borrow.create!(
      asset: @asset,
      created_by: @teacher,
      borrow_source: "manual_request",
      borrower_type: "teacher",
      borrower_name: @teacher.full_name,
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      workflow_state: "pending"
    )

    @other_borrow = Borrow.create!(
      asset: @asset,
      created_by: @other_teacher,
      borrow_source: "manual_request",
      borrower_type: "teacher",
      borrower_name: @other_teacher.full_name,
      starts_at: 3.hours.from_now,
      ends_at: 4.hours.from_now,
      workflow_state: "pending"
    )
  end

  test "teacher cannot access system pages and cannot change borrow records" do
    login_as(@teacher)

    get root_path
    assert_redirected_to borrows_path

    get assets_path
    assert_redirected_to borrows_path

    get rooms_path
    assert_redirected_to borrows_path

    get reports_path
    assert_redirected_to borrows_path

    get users_path
    assert_redirected_to borrows_path

    get edit_borrow_path(@own_borrow)
    assert_redirected_to borrows_path

    patch borrow_path(@own_borrow), params: { borrow: { purpose: "Sửa trái quyền" } }
    assert_redirected_to borrows_path

    delete borrow_path(@own_borrow)
    assert_redirected_to borrows_path

    patch confirm_return_borrow_path(@own_borrow)
    assert_redirected_to borrows_path
  end

  test "teacher can create and view own borrow but cannot view other users borrow" do
    login_as(@teacher)

    assert_difference("Borrow.count", 1) do
      post borrows_path, params: {
        borrow: {
          asset_id: @asset.id,
          starts_at: 5.hours.from_now,
          ends_at: 6.hours.from_now,
          purpose: "Mượn thiết bị dạy học"
        }
      }
    end
    assert_redirected_to borrows_path

    created = Borrow.order(:id).last
    assert_equal @teacher.id, created.created_by_id
    assert_equal "pending", created.workflow_state

    get borrow_path(@own_borrow)
    assert_response :success
    assert_match @teacher.full_name, @response.body

    get borrow_path(@other_borrow)
    assert_redirected_to borrows_path
  end

  test "approver can view all borrows and approve or reject" do
    login_as(@approver)

    get borrows_path
    assert_response :success
    assert_match @teacher.full_name, @response.body
    assert_match @other_teacher.full_name, @response.body

    patch approve_borrow_path(@own_borrow)
    assert_redirected_to borrows_path
    assert_equal "approved", @own_borrow.reload.workflow_state

    patch reject_borrow_path(@own_borrow)
    assert_redirected_to borrows_path
    assert_equal "rejected", @own_borrow.reload.workflow_state
  end

  test "approver cannot create borrow request" do
    login_as(@approver)

    get new_borrow_path
    assert_redirected_to borrows_path

    assert_no_difference("Borrow.count") do
      post borrows_path, params: {
        borrow: {
          asset_id: @asset.id,
          starts_at: 7.hours.from_now,
          ends_at: 8.hours.from_now,
          purpose: "Không được tạo"
        }
      }
    end
    assert_redirected_to borrows_path
  end
end
