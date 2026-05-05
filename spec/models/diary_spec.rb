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
  end

  describe "dependent: :destroy" do
    it "diaryを削除するとweather_recordも削除される" do
      diary = create(:diary)
      create(:weather_record, diary: diary)
      expect { diary.destroy }.to change(WeatherRecord, :count).by(-1)
    end
  end

  describe "#attach_weather!" do
    let(:diary) { create(:diary) }
    let(:weather_data) do
      {
        city_name: "Tokyo",
        weather_main: "Rain",
        description: "小雨",
        temp: 14.5,
        humidity: 82,
        rainfall_mm: 3.2
      }
    end

    context "WeatherService が天気データを返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return(weather_data)
      end

      it "weather_record が作成される" do
        expect { diary.attach_weather!(latitude: 35.68, longitude: 139.65) }.to change { WeatherRecord.count }.by(1)
      end

      it "weather_record のカラムに正しい値が設定される" do
        diary.attach_weather!(latitude: 35.68, longitude: 139.65)
        expect(diary.weather_record.city_name).to eq("Tokyo")
        expect(diary.weather_record.weather_main).to eq("Rain")
      end
    end

    context "WeatherService が nil を返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return(nil)
      end

      it "weather_record が作成されない" do
        expect { diary.attach_weather!(latitude: 35.68, longitude: 139.65) }.not_to change { WeatherRecord.count }
      end
    end

    context "WeatherService が空 Hash を返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return({})
      end

      it "weather_record が作成されない" do
        expect { diary.attach_weather!(latitude: 35.68, longitude: 139.65) }.not_to change { WeatherRecord.count }
      end
    end
  end
end
