class WeatherService
  LATITUDE  = 35.6762
  LONGITUDE = 139.6503
  CITY_NAME = "Tokyo"
  BASE_URL  = "https://api.openweathermap.org"
  ENDPOINT  = "/data/2.5/weather"

  def initialize(api_key: ENV["OPENWEATHER_API_KEY"])
    @api_key = api_key
  end

  def fetch
    return nil if @api_key.blank?

    response = build_connection.get(ENDPOINT) do |req|
      req.params.merge!(
        lat:   LATITUDE,
        lon:   LONGITUDE,
        units: "metric",
        lang:  "ja",
        appid: @api_key
      )
    end
    return nil unless response.success?

    parse(response.body)
  rescue Faraday::Error => e
    Rails.logger.error("[WeatherService] Faraday error: #{e.class}")
    nil
  end

  private

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
      city_name:    body["name"] || CITY_NAME,
      weather_main: weather["main"],
      description:  weather["description"],
      temp:         main["temp"],
      humidity:     main["humidity"],
      rainfall_mm:  body.dig("rain", "1h").to_f
    }
  end
end
