require "rails_helper"

RSpec.describe DiaryPolicy do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:diary) { create(:diary, user: user) }

  def policy(record, acting_as: user)
    described_class.new(acting_as, record)
  end

  describe "index?" do
    it "ログイン済みユーザーなら許可する" do
      expect(policy(Diary).index?).to be true
    end
  end

  describe "new? / create?" do
    it "ログイン済みユーザーなら許可する" do
      expect(policy(Diary).new?).to be true
      expect(policy(Diary).create?).to be true
    end
  end

  describe "show?" do
    it "diaryの所有者なら許可する" do
      expect(policy(diary).show?).to be true
    end

    it "diaryの所有者でなければ拒否する" do
      expect(policy(diary, acting_as: other).show?).to be false
    end
  end

  describe "edit? / update?" do
    it "diaryの所有者なら許可する" do
      expect(policy(diary).edit?).to be true
      expect(policy(diary).update?).to be true
    end

    it "diaryの所有者でなければ拒否する" do
      expect(policy(diary, acting_as: other).edit?).to be false
      expect(policy(diary, acting_as: other).update?).to be false
    end
  end

  describe "destroy?" do
    it "diaryの所有者なら許可する" do
      expect(policy(diary).destroy?).to be true
    end

    it "diaryの所有者でなければ拒否する" do
      expect(policy(diary, acting_as: other).destroy?).to be false
    end
  end

  describe DiaryPolicy::Scope do
    it "自分のdiaryのみを返す" do
      own_diary   = create(:diary, user: user)
      other_diary = create(:diary, user: other)
      resolved = described_class.new(user, Diary).resolve
      expect(resolved).to include(own_diary)
      expect(resolved).not_to include(other_diary)
    end
  end
end
