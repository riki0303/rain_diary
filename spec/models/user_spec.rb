require 'rails_helper'

RSpec.describe User, type: :model do
  describe "アソシエーション" do
    it "複数のdiaryを持てる" do
      user = create(:user)
      create_list(:diary, 2, user: user)
      expect(user.diaries.count).to eq(2)
    end
  end

  describe "dependent: :destroy" do
    it "userを削除するとdiaryも削除される" do
      user = create(:user)
      create(:diary, user: user)
      expect { user.destroy }.to change(Diary, :count).by(-1)
    end
  end
end
