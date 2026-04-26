class WeatherRecord < ApplicationRecord
  belongs_to :diary

  validates :city_name, presence: true
  validates :weather_main, presence: true
end
