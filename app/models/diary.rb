class Diary < ApplicationRecord
  belongs_to :user
  has_one :weather_record, dependent: :destroy

  delegate :weather_main, :description, :temp, :humidity, :rainfall_mm,
           to: :weather_record, allow_nil: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 10_000 }
  validates :recorded_on, presence: true
  validates :mood, presence: true, numericality: { only_integer: true }, inclusion: { in: 1..5 }

  validate :recorded_on_must_be_today, on: :create
  validate :recorded_on_must_not_change, on: :update

  def attach_weather!(latitude:, longitude:)
    weather_data = WeatherService.new(latitude:, longitude:).fetch
    return if weather_data.blank?

    create_weather_record!(weather_data)
  end

  private

  def recorded_on_must_be_today
    return if recorded_on.blank?

    errors.add(:recorded_on, "は本日のみ指定できます") if recorded_on != Date.current
  end

  def recorded_on_must_not_change
    errors.add(:recorded_on, "は変更できません") if recorded_on_changed?
  end
end
