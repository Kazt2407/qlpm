require "test_helper"

class VeyonModelsTest < ActiveSupport::TestCase
  setup do
    room = Room.create!(code: "RM-VM", name: "Room VM", room_type: "computer_room", status: "active")
    @asset = Asset.create!(
      code: "AS-VM",
      name: "Asset VM",
      asset_type: "computer",
      category: "computer",
      room: room,
      status: "active"
    )
  end

  test "veyon host validates endpoint uniqueness" do
    VeyonHost.create!(asset: @asset, host: "pc-test.local", service_port: 11_100, enabled: true)

    another_asset = Asset.create!(
      code: "AS-VM-2",
      name: "Asset VM 2",
      asset_type: "computer",
      category: "computer",
      room: @asset.room,
      status: "active"
    )

    duplicate = VeyonHost.new(asset: another_asset, host: "pc-test.local", service_port: 11_100, enabled: true)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:host], "has already been taken"
  end

  test "veyon action validates feature key" do
    user = User.create!(
      full_name: "Veyon User",
      email: "veyon-user@example.com",
      role: "approver",
      user_type: "teacher",
      password: "password123"
    )
    host = VeyonHost.create!(asset: @asset, host: "pc-action.local", service_port: 11_100, enabled: true)

    action = VeyonAction.new(
      user: user,
      asset: @asset,
      veyon_host: host,
      host: host.target_endpoint,
      feature_key: "invalid",
      status: "sent"
    )

    assert_not action.valid?
    assert_includes action.errors[:feature_key], "is not included in the list"
  end
end
