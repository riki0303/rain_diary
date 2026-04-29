class Diary < ApplicationRecord
  belongs_to :user
  has_one :weather_record, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true
  validates :recorded_on, presence: true
  validates :mood, presence: true, numericality: { only_integer: true }, inclusion: { in: 1..5 }

  def attach_weather!
    weather_data = WeatherService.new.fetch
    return if weather_data.blank?

    create_weather_record!(weather_data)
  end
end
