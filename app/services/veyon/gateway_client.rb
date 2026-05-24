require "net/http"
require "uri"
require "json"

module Veyon
  class GatewayClient
    Response = Struct.new(
      :success,
      :status,
      :body,
      :raw_body,
      :content_type,
      :error_code,
      :error_message,
      keyword_init: true
    ) do
      def success?
        success
      end
    end

    FEATURE_UIDS = {
      "screen_lock" => "ccb535a2-1d24-4cc1-a709-8b47d2b2ac79",
      "input_devices_lock" => "e4a77879-e544-4fec-bc18-e534f33b934c",
      "user_logoff" => "7311d43d-ab53-439e-a03a-8cb25f7ed526",
      "reboot" => "4f7d98f0-395a-4fff-b968-e49b8d0f748c",
      "power_down" => "6f5a27a0-0e2f-496e-afcc-7aae62eede10",
      "text_message" => "e75ae9c8-ac17-4d00-8f0d-019348346208",
      "open_website" => "8a11a75d-b3db-48b6-b9cb-f8422ddd5b0c",
      "start_app" => "da9ca56a-b2ad-4fff-8f8a-929b2927b442"
    }.freeze

    AUTH_METHODS = {
      "auth_keys" => "0c69b301-81b4-42d6-8fae-128cdd113314",
      "auth_ldap" => "6f0a491e-c1c6-4338-8244-f823b0bf8670",
      "auth_logon" => "63611f7c-b457-42c7-832e-67d0f9281085",
      "auth_simple" => "73430b14-ef69-4c75-a145-ba635d1cc676"
    }.freeze

    def initialize(base_url: AppSettings.veyon_gateway_base_url, api_key: AppSettings.veyon_gateway_api_key)
      @base_url = base_url.to_s.chomp("/")
      @api_key = api_key.to_s
    end

    def enabled?
      AppSettings.veyon_enabled? && @base_url.present? && @api_key.present?
    end

    def open_connection(host:, auth_method:, credentials: {})
      request_json(
        :post,
        "/v1/connections/open",
        body: {
          host: host,
          auth_method: auth_method,
          credentials: credentials
        }
      )
    end

    def close_connection(connection_uid)
      request_json(:delete, "/v1/connections/#{connection_uid}")
    end

    def execute_feature(host:, feature_key:, active:, arguments: nil)
      payload = { active: !!active }
      payload[:arguments] = arguments if arguments.present?

      request_json(:post, "/v1/hosts/#{host}/features/#{feature_key}", body: payload)
    end

    def framebuffer(host:, format: "jpeg", width: nil, height: nil, quality: nil)
      params = {
        format: format,
        width: width,
        height: height,
        quality: quality
      }.compact

      request_binary(:get, "/v1/hosts/#{host}/framebuffer", params: params)
    end

    def user_info(host)
      request_json(:get, "/v1/hosts/#{host}/user")
    end

    def session_info(host)
      request_json(:get, "/v1/hosts/#{host}/session")
    end

    private

    def request_json(method, path, params: nil, body: nil)
      response = perform_request(method, path, params: params, body: body)
      parsed = parse_json(response.raw_body)

      if response.success?
        response.body = parsed || {}
      else
        response.error_code = parsed&.dig("error", "code")&.to_s
        response.error_message = parsed&.dig("error", "message") || response.error_message
        response.body = parsed || {}
      end

      response
    end

    def request_binary(method, path, params: nil)
      perform_request(method, path, params: params)
    end

    def perform_request(method, path, params: nil, body: nil)
      return disabled_response unless enabled?

      uri = build_uri(path, params)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 15

      request = request_class_for(method).new(uri)
      request["X-API-Key"] = @api_key
      request["Content-Type"] = "application/json"
      request.body = JSON.dump(body) if body

      http_response = http.request(request)
      raw_body = http_response.body.to_s
      status = http_response.code.to_i
      content_type = http_response["content-type"].to_s

      Response.new(
        success: status.between?(200, 299),
        status: status,
        raw_body: raw_body,
        content_type: content_type,
        error_message: status.between?(200, 299) ? nil : "Gateway trả về HTTP #{status}"
      )
    rescue StandardError => e
      Response.new(
        success: false,
        status: 0,
        raw_body: "",
        content_type: "",
        error_message: e.message
      )
    end

    def disabled_response
      Response.new(
        success: false,
        status: 0,
        raw_body: "",
        content_type: "",
        error_code: "disabled",
        error_message: "Tích hợp Veyon đang tắt hoặc thiếu cấu hình gateway."
      )
    end

    def build_uri(path, params)
      uri = URI.parse("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(params) if params.present?
      uri
    end

    def request_class_for(method)
      {
        get: Net::HTTP::Get,
        post: Net::HTTP::Post,
        patch: Net::HTTP::Patch,
        put: Net::HTTP::Put,
        delete: Net::HTTP::Delete
      }.fetch(method.to_sym)
    end

    def parse_json(raw_body)
      return nil if raw_body.blank?

      JSON.parse(raw_body)
    rescue JSON::ParserError
      nil
    end
  end
end
