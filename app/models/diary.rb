class Diary < ApplicationRecord
  belongs_to :user
  has_one :weather_record, dependent: :destroy

  delegate :weather_main, :description, :temp, :humidity, :rainfall_mm,
           to: :weather_record, allow_nil: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 10_000 }
  validates :recorded_on, presence: true
  validates :mood, presence: true, numericality: { only_integer: true }, inclusion: { in: 1..5 }

  def attach_weather!
    weather_data = WeatherService.new.fetch
    return if weather_data.blank?

    create_weather_record!(weather_data)
  end
end
