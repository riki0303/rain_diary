require "rails_helper"

RSpec.describe DiariesHelper, type: :helper do
  describe "#mood_dots" do
    it "mood=3で塗りつぶしが3個、空が2個含まれる" do
      output = helper.mood_dots(3)
      expect(output.scan("bi-circle-fill").size).to eq 3
      expect(output.scan(/bi-circle(?!-fill)/).size).to eq 2
    end

    it "mood=5で塗りつぶしが5個含まれる" do
      output = helper.mood_dots(5)
      expect(output.scan("bi-circle-fill").size).to eq 5
    end

    it "mood=1で空が4個含まれる" do
      output = helper.mood_dots(1)
      expect(output.scan(/bi-circle(?!-fill)/).size).to eq 4
    end
  end

  describe "#weather_icon_class" do
    it "Rainに対応するアイコンクラスを返す" do
      expect(helper.weather_icon_class("Rain")).to eq "bi-cloud-rain"
    end

    it "未定義のweather_mainではデフォルトを返す" do
      expect(helper.weather_icon_class("Unknown")).to eq "bi-cloud"
    end
  end

  describe "#weather_icon_tag" do
    it "i要素にweather_mainに応じたbiクラスを付与する" do
      expect(helper.weather_icon_tag("Rain")).to include("bi", "bi-cloud-rain")
    end

    it "extra_classが追加される" do
      expect(helper.weather_icon_tag("Rain", extra_class: "text-info")).to include("text-info")
    end
  end
end
