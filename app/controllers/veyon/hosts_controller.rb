module Veyon
  class HostsController < ApplicationController
    before_action :require_borrow_reviewer!
    before_action :set_veyon_host, only: %i[show edit update destroy framebuffer execute_feature refresh_status]
    before_action :require_admin!, only: %i[new create edit update destroy]

    def index
      @veyon_hosts = VeyonHost.includes(asset: :room).recent
      @veyon_hosts = @veyon_hosts.where(enabled: active_model_boolean(params[:enabled])) if params[:enabled].present?
      @veyon_hosts = @veyon_hosts.where(asset_id: params[:asset_id]) if params[:asset_id].present?
      @veyon_hosts = @veyon_hosts.where("host LIKE ?", "%#{params[:q]}%") if params[:q].present?

      @veyon_hosts, @page, @per_page, @total_pages, @total_count = paginate_scope(@veyon_hosts)
      @assets_for_filter = Asset.order(:code)
    end

    def rooms
      @rooms = Room.includes(assets: :veyon_host).order(:name)
      @selected_room = params[:room_id].present? ? Room.find_by(id: params[:room_id]) : @rooms.first
      @allowed_features = allowed_features_for(current_user)
      @veyon_hosts = if @selected_room
        VeyonHost.enabled.includes(asset: :room).where(assets: { room_id: @selected_room.id }).references(:asset).order(:host)
      else
        VeyonHost.none
      end
    end

    def execute_room_feature
      room = Room.find(params[:room_id])
      feature_key = params[:feature_key].to_s

      unless allowed_features_for(current_user).include?(feature_key)
        redirect_to rooms_veyon_hosts_path(room_id: room.id), alert: "Bạn không có quyền dùng thao tác này."
        return
      end

      active, arguments, payload_error = build_feature_payload(feature_key)
      if payload_error.present?
        redirect_to rooms_veyon_hosts_path(room_id: room.id), alert: payload_error
        return
      end

      hosts = VeyonHost.enabled.includes(:asset).where(assets: { room_id: room.id }).references(:asset)
      success_count = 0
      failure_count = 0

      hosts.each do |host|
        response = gateway_client.execute_feature(
          host: host.target_endpoint,
          feature_key: feature_key,
          active: active,
          arguments: arguments
        )
        action = create_action_log_for(host, feature_key, active, arguments)

        if response.success?
          success_count += 1
          action.update!(status: "success", response_payload_json: response.body.is_a?(Hash) ? response.body : {})
          host.update_column(:last_seen_at, Time.current)
        else
          failure_count += 1
          action.update!(
            status: "failed",
            response_payload_json: response.body.is_a?(Hash) ? response.body : {},
            error_code: response.error_code,
            error_message: response.error_message
          )
        end
      end

      redirect_to rooms_veyon_hosts_path(room_id: room.id), notice: "Đã gửi lệnh cho #{success_count} máy, lỗi #{failure_count} máy."
    end

    def show
      @recent_actions = @veyon_host.veyon_actions.includes(:user, :borrow).recent.limit(20)
      @allowed_features = allowed_features_for(current_user)
    end

    def new
      @veyon_host = VeyonHost.new(service_port: 11_100, enabled: true)
      load_form_data
    end

    def create
      @veyon_host = VeyonHost.new(normalized_veyon_host_params)
      apply_metadata_parse_error(@veyon_host)

      if @veyon_host.errors.none? && @veyon_host.save
        redirect_to veyon_host_path(@veyon_host), notice: "Đã tạo cấu hình máy Veyon."
      else
        load_form_data
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_data
    end

    def update
      @veyon_host.assign_attributes(normalized_veyon_host_params)
      apply_metadata_parse_error(@veyon_host)

      if @veyon_host.errors.none? && @veyon_host.save
        redirect_to veyon_host_path(@veyon_host), notice: "Đã cập nhật cấu hình máy Veyon."
      else
        load_form_data
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @veyon_host.destroy
      redirect_to veyon_hosts_path, notice: "Đã xóa cấu hình máy Veyon."
    end

    def refresh_status
      response = gateway_client.user_info(@veyon_host.target_endpoint)

      if response.success?
        @veyon_host.update(last_seen_at: Time.current)
        redirect_to veyon_host_path(@veyon_host), notice: "Đã cập nhật trạng thái kết nối."
      else
        redirect_to veyon_host_path(@veyon_host), alert: "Không thể kết nối cổng trung gian Veyon: #{response.error_message}"
      end
    end

    def framebuffer
      response = gateway_client.framebuffer(
        host: @veyon_host.target_endpoint,
        format: AppSettings.veyon_framebuffer_format,
        width: AppSettings.veyon_framebuffer_width,
        height: AppSettings.veyon_framebuffer_height.positive? ? AppSettings.veyon_framebuffer_height : nil,
        quality: AppSettings.veyon_framebuffer_jpeg_quality
      )

      if response.success?
        @veyon_host.update_column(:last_seen_at, Time.current)
        send_data response.raw_body, type: response.content_type.presence || "image/jpeg", disposition: "inline"
      else
        render plain: "Ảnh màn hình không khả dụng: #{response.error_message}", status: :service_unavailable
      end
    end

    def execute_feature
      feature_key = params[:feature_key].to_s

      unless allowed_features_for(current_user).include?(feature_key)
        redirect_to veyon_host_path(@veyon_host), alert: "Bạn không có quyền dùng thao tác này."
        return
      end

      active, arguments, payload_error = build_feature_payload(feature_key)
      if payload_error.present?
        redirect_to veyon_host_path(@veyon_host), alert: payload_error
        return
      end

      action = create_action_log_for(@veyon_host, feature_key, active, arguments)

      response = gateway_client.execute_feature(
        host: @veyon_host.target_endpoint,
        feature_key: feature_key,
        active: active,
        arguments: arguments
      )

      if response.success?
        action.update!(
          status: "success",
          response_payload_json: response.body.is_a?(Hash) ? response.body : {},
          error_code: nil,
          error_message: nil
        )
        @veyon_host.update_column(:last_seen_at, Time.current)
        redirect_to veyon_host_path(@veyon_host), notice: "Đã gửi lệnh #{feature_label(feature_key)}."
      else
        action.update!(
          status: "failed",
          response_payload_json: response.body.is_a?(Hash) ? response.body : {},
          error_code: response.error_code,
          error_message: response.error_message
        )
        redirect_to veyon_host_path(@veyon_host), alert: "Gửi lệnh thất bại: #{response.error_message}"
      end
    end

    private

    def set_veyon_host
      @veyon_host = VeyonHost.find(params[:id])
    end

    def veyon_host_params
      params.require(:veyon_host).permit(:asset_id, :host, :service_port, :enabled, :metadata_json)
    end

    def normalized_veyon_host_params
      attrs = veyon_host_params.to_h
      metadata = attrs["metadata_json"]
      attrs["metadata_json"], @metadata_parse_error = parse_metadata_json(metadata)
      attrs
    end

    def load_form_data
      @assets = Asset.order(:code)
    end

    def gateway_client
      @gateway_client ||= Veyon::GatewayClient.new
    end

    def allowed_features_for(user)
      return AppSettings.veyon_allowed_features_admin if user.admin?
      return AppSettings.veyon_allowed_features_approver if user.approver?

      []
    end

    def feature_label(feature_key)
      {
        "screen_lock" => "Khóa màn hình",
        "input_devices_lock" => "Khóa chuột và bàn phím",
        "user_logoff" => "Đăng xuất người dùng",
        "reboot" => "Khởi động lại máy",
        "power_down" => "Tắt máy",
        "text_message" => "Gửi tin nhắn",
        "open_website" => "Mở trang web",
        "start_app" => "Mở ứng dụng"
      }[feature_key] || feature_key
    end

    def build_feature_payload(feature_key)
      case feature_key
      when "screen_lock", "input_devices_lock"
        [active_feature_state, nil, nil]
      when "text_message"
        text = params[:text].to_s.strip
        return [true, nil, "Nội dung tin nhắn không được để trống."] if text.blank?

        [true, { text: text }, nil]
      when "open_website"
        urls = params[:website_urls].to_s.split(/[,\n]/).map(&:strip).reject(&:blank?)
        return [true, nil, "Danh sách trang web không được để trống."] if urls.blank?

        [true, { websiteUrls: urls }, nil]
      when "start_app"
        applications = params[:applications].to_s.split(/[,\n]/).map(&:strip).reject(&:blank?)
        return [true, nil, "Danh sách ứng dụng không được để trống."] if applications.blank?

        [true, { applications: applications }, nil]
      else
        [true, nil, nil]
      end
    end

    def active_feature_state
      ActiveModel::Type::Boolean.new.cast(params[:active])
    end

    def create_action_log_for(veyon_host, feature_key, active, arguments)
      VeyonAction.create!(
        user: current_user,
        borrow: matching_borrow_for_audit(veyon_host),
        asset: veyon_host.asset,
        veyon_host: veyon_host,
        host: veyon_host.target_endpoint,
        feature_key: feature_key,
        status: "sent",
        request_payload_json: {
          active: active,
          arguments: arguments
        }
      )
    end

    def matching_borrow_for_audit(veyon_host)
      return nil if params[:borrow_id].blank?

      Borrow.where(id: params[:borrow_id], asset_id: veyon_host.asset_id).first
    end

    def active_model_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def parse_metadata_json(raw_value)
      return [nil, nil] if raw_value.blank?
      return [raw_value, nil] if raw_value.is_a?(Hash)

      [JSON.parse(raw_value), nil]
    rescue JSON::ParserError
      [nil, "Dữ liệu JSON bổ sung không đúng định dạng."]
    end

    def apply_metadata_parse_error(record)
      return if @metadata_parse_error.blank?

      record.errors.add(:metadata_json, @metadata_parse_error)
    end
  end
end
