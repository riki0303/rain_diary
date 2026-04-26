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
    end

    context "body" do
      it "bodyがなければ無効" do
        expect(build(:diary, body: nil)).not_to be_valid
      end

      it "bodyがあれば有効" do
        expect(build(:diary, body: "本文")).to be_valid
      end
    end

    context "recorded_on" do
      it "recorded_onがなければ無効" do
        expect(build(:diary, recorded_on: nil)).not_to be_valid
      end

      it "recorded_onがあれば有効" do
        expect(build(:diary, recorded_on: Date.current)).to be_valid
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
end