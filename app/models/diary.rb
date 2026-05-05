class Diary < ApplicationRecord
  belongs_to :user
  has_one :weather_record, dependent: :destroy

  attr_accessor :current_weather_main

  delegate :weather_main, :description, :temp, :humidity, :rainfall_mm,
           to: :weather_record, allow_nil: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :body, presence: true, length: { maximum: 10_000 }
  validates :recorded_on, presence: true
  validates :mood, presence: true, numericality: { only_integer: true }, inclusion: { in: 1..5 }

  validate :recorded_on_must_be_today, on: :create
  validate :weather_must_be_rainy, on: :create
  validate :recorded_on_must_not_change, on: :update

  def assign_weather(weather_data)
    self.current_weather_main = weather_data[:weather_main] # バリデーションチェック用
    build_weather_record(weather_data)
  end

  private

  def recorded_on_must_be_today
    return if recorded_on.blank?

    errors.add(:recorded_on, "は本日のみ指定できます") if recorded_on != Date.current
  end

  def recorded_on_must_not_change
    errors.add(:recorded_on, "は変更できません") if recorded_on_changed?
  end

  def weather_must_be_rainy
    return if WeatherRecord.rainy?(current_weather_main)

    errors.add(:base, "雨の日のみ日記を記録できます")
  end
end
