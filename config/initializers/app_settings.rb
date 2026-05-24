module AppSettings
  module_function

  def fetch_integer(key, default)
    Integer(ENV.fetch(key, default))
  rescue ArgumentError, TypeError
    default
  end

  def fetch_integer_list(key, default)
    raw = ENV.fetch(key, default.join(","))
    values = raw.split(",").map(&:strip).reject(&:empty?).map { |v| Integer(v) }
    values.presence || default
  rescue ArgumentError, TypeError
    default
  end

  def fetch_string_list(key, default)
    raw = ENV.fetch(key, default.join(","))
    values = raw.split(",").map(&:strip).reject(&:blank?)
    values.presence || default
  end

  def pagination_default_per_page
    fetch_integer("APP_PAGINATION_DEFAULT_PER_PAGE", 15)
  end

  def pagination_max_per_page
    fetch_integer("APP_PAGINATION_MAX_PER_PAGE", 100)
  end

  def pagination_options
    fetch_integer_list("APP_PAGINATION_OPTIONS", [15, 30, 50])
  end

  def borrow_default_duration_minutes
    fetch_integer("APP_BORROW_DEFAULT_DURATION_MINUTES", 120)
  end

  def report_top_borrowers_limit
    fetch_integer("APP_REPORT_TOP_BORROWERS_LIMIT", 5)
  end

  def report_attention_assets_limit
    fetch_integer("APP_REPORT_ATTENTION_ASSETS_LIMIT", 5)
  end

  def report_months_lookback
    fetch_integer("APP_REPORT_MONTHS_LOOKBACK", 12)
  end

  def app_default_host
    ENV.fetch("APP_HOST", "localhost")
  end

  def app_default_port
    fetch_integer("APP_PORT", 3000)
  end

  def veyon_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("VEYON_ENABLED", false))
  end

  def veyon_gateway_base_url
    ENV.fetch("VEYON_GATEWAY_BASE_URL", "http://veyon-gateway:8088")
  end

  def veyon_gateway_api_key
    ENV.fetch("VEYON_GATEWAY_API_KEY", "")
  end

  def veyon_framebuffer_format
    format = ENV.fetch("VEYON_FRAMEBUFFER_FORMAT", "jpeg").to_s.downcase
    %w[jpeg png].include?(format) ? format : "jpeg"
  end

  def veyon_framebuffer_width
    fetch_integer("VEYON_FRAMEBUFFER_WIDTH", 360)
  end

  def veyon_framebuffer_height
    fetch_integer("VEYON_FRAMEBUFFER_HEIGHT", 0)
  end

  def veyon_framebuffer_jpeg_quality
    quality = fetch_integer("VEYON_FRAMEBUFFER_JPEG_QUALITY", 60)
    return 60 if quality < 1 || quality > 100

    quality
  end

  def veyon_framebuffer_poll_interval_ms
    fetch_integer("VEYON_FRAMEBUFFER_POLL_INTERVAL_MS", 2000)
  end

  def veyon_allowed_features_admin
    fetch_string_list(
      "VEYON_ALLOWED_FEATURES_ADMIN",
      %w[
        screen_lock
        input_devices_lock
        user_logoff
        reboot
        power_down
        text_message
        open_website
        start_app
      ]
    )
  end

  def veyon_allowed_features_approver
    fetch_string_list(
      "VEYON_ALLOWED_FEATURES_APPROVER",
      %w[
        screen_lock
        input_devices_lock
        user_logoff
        text_message
        open_website
        start_app
      ]
    )
  end
end
