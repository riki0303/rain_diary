require "rails_helper"

RSpec.describe WeatherRecord, type: :model do
  describe "アソシエーション" do
    it "diaryに属している" do
      weather_record = build(:weather_record)
      expect(weather_record.diary).to be_present
    end
  end

  describe "バリデーション" do
    context "city_name" do
      it "city_nameがなければ無効" do
        expect(build(:weather_record, city_name: nil)).not_to be_valid
      end

      it "city_nameがあれば有効" do
        expect(build(:weather_record, city_name: "Tokyo")).to be_valid
      end
    end

    context "weather_main" do
      it "weather_mainがなければ無効" do
        expect(build(:weather_record, weather_main: nil)).not_to be_valid
      end

      it "weather_mainがあれば有効" do
        expect(build(:weather_record, weather_main: "Rain")).to be_valid
      end
    end
  end

  describe ".rainy?" do
    it "weather_mainがRainの場合はtrue" do
      expect(WeatherRecord.rainy?("Rain")).to be true
    end

    it "weather_mainがDrizzleの場合はtrue" do
      expect(WeatherRecord.rainy?("Drizzle")).to be true
    end

    it "weather_mainがClearの場合はfalse" do
      expect(WeatherRecord.rainy?("Clear")).to be false
    end

    it "weather_mainがCloudsの場合はfalse" do
      expect(WeatherRecord.rainy?("Clouds")).to be false
    end
  end
end
