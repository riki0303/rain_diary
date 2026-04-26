FactoryBot.define do
  factory :weather_record do
    association :diary
    city_name { "Tokyo" }
    weather_main { "Rain" }
    description { "小雨" }
    temp { 14.5 }
    humidity { 82 }
    rainfall_mm { 3.2 }
  end
end
