require "test_helper"

class VeyonHostsAccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      full_name: "Admin Veyon",
      email: "admin-veyon@example.com",
      role: "admin",
      user_type: "admin",
      password: "password123"
    )
    @approver = User.create!(
      full_name: "Approver Veyon",
      email: "approver-veyon@example.com",
      role: "approver",
      user_type: "teacher",
      password: "password123"
    )
    @teacher = User.create!(
      full_name: "Teacher Veyon",
      email: "teacher-veyon@example.com",
      role: "user",
      user_type: "teacher",
      password: "password123"
    )

    room = Room.create!(code: "RM-VY", name: "Room Veyon", room_type: "computer_room", status: "active")
    @asset = Asset.create!(
      code: "AS-VY",
      name: "Asset Veyon",
      asset_type: "computer",
      category: "computer",
      room: room,
      status: "active"
    )
    @host = VeyonHost.create!(asset: @asset, host: "pc-01.lab.local", service_port: 11_100, enabled: true)
  end

  test "teacher cannot access veyon hosts pages" do
    login_as(@teacher)

    get veyon_hosts_path
    assert_redirected_to borrows_path

    get veyon_host_path(@host)
    assert_redirected_to borrows_path
  end

  test "approver can access hosts index and show" do
    login_as(@approver)

    get veyon_hosts_path
    assert_response :success
    assert_match @host.host, @response.body

    get veyon_host_path(@host)
    assert_response :success
    assert_match @asset.code, @response.body
  end

  test "approver cannot create host mappings" do
    login_as(@approver)

    get new_veyon_host_path
    assert_redirected_to borrows_path

    assert_no_difference("VeyonHost.count") do
      post veyon_hosts_path, params: {
        veyon_host: {
          asset_id: @asset.id,
          host: "pc-02.lab.local",
          service_port: 11_100,
          enabled: true
        }
      }
    end
    assert_redirected_to borrows_path
  end

  test "approver executes allowed feature and action is logged" do
    login_as(@approver)

    response = Veyon::GatewayClient::Response.new(
      success: true,
      status: 200,
      body: { "success" => true },
      raw_body: "{\"success\":true}",
      content_type: "application/json"
    )

    fake_client = Object.new
    fake_client.define_singleton_method(:execute_feature) { |**_kwargs| response }

    Veyon::GatewayClient.stub :new, fake_client do
      assert_difference("VeyonAction.count", 1) do
        post execute_feature_veyon_host_path(@host), params: {
          feature_key: "screen_lock",
          active: true
        }
      end
    end

    assert_redirected_to veyon_host_path(@host)
    action = VeyonAction.order(:id).last
    assert_equal @approver.id, action.user_id
    assert_equal "screen_lock", action.feature_key
    assert_equal "success", action.status
  end

  test "approver cannot run disallowed reboot feature" do
    login_as(@approver)

    assert_no_difference("VeyonAction.count") do
      post execute_feature_veyon_host_path(@host), params: { feature_key: "reboot" }
    end

    assert_redirected_to veyon_host_path(@host)
  end
end
