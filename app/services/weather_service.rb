class WeatherService
  BASE_URL  = "https://api.openweathermap.org"
  ENDPOINT  = "/data/2.5/weather"
  CACHE_TTL = 1.hour

  def initialize(latitude:, longitude:, api_key: ENV["OPENWEATHER_API_KEY"])
    @latitude  = latitude
    @longitude = longitude
    @api_key   = api_key
  end

  def fetch
    cached = Rails.cache.read(cache_key)
    return cached if cached

    result = fetch_uncached
    Rails.cache.write(cache_key, result, expires_in: CACHE_TTL) if weather_data?(result)
    result
  end

  private

  def cache_key
    "weather:current:#{@latitude.to_f.round(2)}:#{@longitude.to_f.round(2)}"
  end

  def fetch_uncached
    return nil if @api_key.blank?

    Rails.logger.debug("[WeatherService] calling API")

    response = build_connection.get(ENDPOINT) do |req|
      req.params.merge!(
        lat:   @latitude,
        lon:   @longitude,
        units: "metric",
        lang:  "ja",
        appid: @api_key
      )
    end

    return :bad_request  if response.status == 400
    return :unauthorized if response.status == 401
    return :not_found    if response.status == 404
    return :rate_limited if response.status == 429
    return :server_error if response.status.between?(500, 599)
    return nil unless response.success?

    parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("[WeatherService] Faraday error: #{e.class}")
    nil
  end

  def build_connection
    Faraday.new(url: BASE_URL) do |f|
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def parse(body)
    weather = body.dig("weather", 0) || {}
    main    = body["main"] || {}
    {
      city_name:    body["name"],
      weather_main: weather["main"],
      description:  weather["description"],
      temp:         main["temp"],
      humidity:     main["humidity"],
      rainfall_mm:  body.dig("rain", "1h").to_f
    }
  end

  def weather_data?(result)
    result.is_a?(Hash)
  end
end
