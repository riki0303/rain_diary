FactoryBot.define do
  factory :diary do
    association :user
    title { "雨の日に映画を見た" }
    body { "家でずっとNetflixを見ていた。" }
    mood { 3 }
    recorded_on { Date.current }
    current_weather_main { "Rain" }
  end
end
