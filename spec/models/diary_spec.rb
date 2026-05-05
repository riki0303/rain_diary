require "rails_helper"

RSpec.describe Diary, type: :model do
  describe "アソシエーション" do
    it "userに属している" do
      diary = build(:diary)
      expect(diary.user).to be_present
    end

    it "weather_recordを1件持てる" do
      diary = create(:diary)
      weather_record = create(:weather_record, diary: diary)
      expect(diary.weather_record).to eq(weather_record)
    end
  end

  describe "バリデーション" do
    context "title" do
      it "titleがなければ無効" do
        expect(build(:diary, title: nil)).not_to be_valid
      end

      it "titleがあれば有効" do
        expect(build(:diary, title: "タイトル")).to be_valid
      end

      it "titleが100文字なら有効" do
        expect(build(:diary, title: "a" * 100)).to be_valid
      end

      it "titleが101文字なら無効" do
        expect(build(:diary, title: "a" * 101)).not_to be_valid
      end
    end

    context "body" do
      it "bodyがなければ無効" do
        expect(build(:diary, body: nil)).not_to be_valid
      end

      it "bodyがあれば有効" do
        expect(build(:diary, body: "本文")).to be_valid
      end

      it "bodyが10000文字なら有効" do
        expect(build(:diary, body: "a" * 10_000)).to be_valid
      end

      it "bodyが10001文字なら無効" do
        expect(build(:diary, body: "a" * 10_001)).not_to be_valid
      end
    end

    context "recorded_on" do
      it "recorded_onがなければ無効" do
        expect(build(:diary, recorded_on: nil)).not_to be_valid
      end

      it "recorded_onがあれば有効" do
        expect(build(:diary, recorded_on: Date.current)).to be_valid
      end

      context "on: :create" do
        it "当日なら有効" do
          expect(build(:diary, recorded_on: Date.current)).to be_valid
        end

        it "昨日なら無効" do
          expect(build(:diary, recorded_on: Date.yesterday)).not_to be_valid
        end

        it "翌日なら無効" do
          expect(build(:diary, recorded_on: Date.tomorrow)).not_to be_valid
        end
      end

      context "on: :update" do
        let!(:diary) { create(:diary, recorded_on: Date.current) }

        it "recorded_onを変更すると無効" do
          diary.recorded_on = Date.yesterday
          expect(diary).not_to be_valid
        end

        it "recorded_on以外を変更しても有効" do
          diary.title = "新しいタイトル"
          expect(diary).to be_valid
        end
      end
    end

    context "mood" do
      it "moodがなければ無効" do
        expect(build(:diary, mood: nil)).not_to be_valid
      end

      it "mood が 1 なら有効" do
        expect(build(:diary, mood: 1)).to be_valid
      end

      it "mood が 5 なら有効" do
        expect(build(:diary, mood: 5)).to be_valid
      end

      it "mood が 0 なら無効" do
        expect(build(:diary, mood: 0)).not_to be_valid
      end

      it "mood が 6 なら無効" do
        expect(build(:diary, mood: 6)).not_to be_valid
      end

      it "mood が小数（3.5）なら無効" do
        diary = build(:diary, mood: 3.5)
        expect(diary).not_to be_valid
      end
    end

    # TODO: context update にまとめる
    context "雨判定 (current_weather_main)" do
      it "current_weather_main が Rain なら有効" do
        expect(build(:diary, current_weather_main: "Rain")).to be_valid
      end

      it "current_weather_main が Drizzle なら有効（境界値）" do
        expect(build(:diary, current_weather_main: "Drizzle")).to be_valid
      end

      it "current_weather_main が Clear なら無効" do
        diary = build(:diary, current_weather_main: "Clear")
        expect(diary).not_to be_valid
        expect(diary.errors[:base]).to include("雨の日のみ日記を記録できます")
      end

      it "current_weather_main が Clouds なら無効" do
        diary = build(:diary, current_weather_main: "Clouds")
        expect(diary).not_to be_valid
        expect(diary.errors[:base]).to include("雨の日のみ日記を記録できます")
      end

      it "current_weather_main が Thunderstorm なら無効" do
        diary = build(:diary, current_weather_main: "Thunderstorm")
        expect(diary).not_to be_valid
        expect(diary.errors[:base]).to include("雨の日のみ日記を記録できます")
      end

      it "current_weather_main が nil なら無効" do
        diary = build(:diary, current_weather_main: nil)
        expect(diary).not_to be_valid
        expect(diary.errors[:base]).to include("雨の日のみ日記を記録できます")
      end

      context "on: :update" do
        let!(:diary) { create(:diary) }

        it "current_weather_main 未設定でも更新時には有効" do
          diary.current_weather_main = nil
          diary.title = "新しいタイトル"
          expect(diary).to be_valid
        end
      end
    end
  end

  describe "dependent: :destroy" do
    it "diaryを削除するとweather_recordも削除される" do
      diary = create(:diary)
      create(:weather_record, diary: diary)
      expect { diary.destroy }.to change(WeatherRecord, :count).by(-1)
    end
  end

  describe "#assign_weather" do
    let(:diary) { build(:diary, current_weather_main: nil) }
    let(:weather_data) do
      { weather_main: "Rain", city_name: "Tokyo", description: "雨",
        temp: 15.0, humidity: 80, rainfall_mm: 3.0 }
    end

    it "current_weather_main にバリデーション用の値をセットする" do
      diary.assign_weather(weather_data)
      expect(diary.current_weather_main).to eq("Rain")
    end

    it "weather_record を build する（保存はしない）" do
      diary.assign_weather(weather_data)
      expect(diary.weather_record).to be_present
      expect(diary.weather_record).to be_new_record
      expect(diary.weather_record.weather_main).to eq("Rain")
    end
  end
end
