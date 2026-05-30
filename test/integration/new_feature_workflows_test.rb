require "test_helper"

class NewFeatureWorkflowsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      full_name: "Feature Admin",
      email: "feature-admin@example.com",
      role: "admin",
      user_type: "admin",
      password: "password123"
    )
    @approver = User.create!(
      full_name: "Feature Approver",
      email: "feature-approver@example.com",
      role: "approver",
      user_type: "teacher",
      password: "password123"
    )
    @teacher = User.create!(
      full_name: "Feature Teacher",
      email: "feature-teacher@example.com",
      role: "user",
      user_type: "teacher",
      password: "password123"
    )
    @room = Room.create!(code: "RM-FEAT", name: "Room Feature", room_type: "computer_room", status: "active")
    @asset = Asset.create!(
      code: "AS-FEAT",
      name: "Asset Feature",
      asset_type: "computer",
      category: "computer",
      room: @room,
      status: "active"
    )
  end

  test "approver can view schedule calendar" do
    Borrow.create!(
      asset: @asset,
      created_by: @teacher,
      borrow_source: "manual_request",
      borrower_type: "teacher",
      borrower_name: @teacher.full_name,
      starts_at: 1.hour.from_now,
      ends_at: 2.hours.from_now,
      workflow_state: "approved"
    )
    login_as(@approver)

    get schedule_path(date: Date.current, room_id: @room.id)

    assert_response :success
    assert_match @asset.code, @response.body
  end

  test "admin can preview and commit borrow csv import" do
    login_as(@admin)
    csv = <<~CSV
      asset_code,borrower_name,borrower_type,starts_at,ends_at,purpose
      #{@asset.code},Imported Class,system,#{2.days.from_now.strftime("%Y-%m-%d 08:00")},#{2.days.from_now.strftime("%Y-%m-%d 09:00")},Practice
    CSV

    assert_no_difference("Borrow.count") do
      post borrow_import_path, params: {
        file: Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "schedule.csv")
      }
    end
    assert_response :success
    assert_match "Hợp lệ", @response.body

    assert_difference("Borrow.count", 1) do
      post commit_borrow_import_path
    end
    assert_redirected_to borrows_path(source: "imported_schedule")
    assert_equal "imported_schedule", Borrow.order(:id).last.borrow_source
  end

  test "teacher can report asset issue and asset moves to maintenance" do
    login_as(@teacher)

    assert_difference("WorkOrder.count", 1) do
      post work_orders_path, params: {
        work_order: {
          asset_id: @asset.id,
          title: "Cannot boot",
          description: "Machine stops at BIOS",
          priority: "high"
        }
      }
    end

    assert_redirected_to work_order_path(WorkOrder.order(:id).last)
    assert_equal "maintenance", @asset.reload.status
  end

  test "admin resolving last work order returns asset to active" do
    work_order = WorkOrder.create!(
      asset: @asset,
      reported_by: @teacher,
      title: "Loose cable",
      priority: "normal",
      status: "open"
    )
    @asset.update!(status: "maintenance")
    login_as(@admin)

    patch work_order_path(work_order), params: {
      work_order: {
        asset_id: @asset.id,
        title: work_order.title,
        priority: "normal",
        status: "resolved",
        resolution_notes: "Cable replaced"
      }
    }

    assert_redirected_to work_orders_path
    assert_equal "resolved", work_order.reload.status
    assert_equal "active", @asset.reload.status
  end
end
