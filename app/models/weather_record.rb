class WeatherRecord < ApplicationRecord
  RAINY_MAINS = %w[Rain Drizzle].freeze

  belongs_to :diary

  validates :city_name, presence: true
  validates :weather_main, presence: true

  def self.rainy?(weather_main)
    RAINY_MAINS.include?(weather_main)
  end
end
