require "rails_helper"

RSpec.describe "Diaries", type: :request do
  let(:user) { create(:user) }

  describe "GET /diaries" do
    context "未ログインの場合" do
      it "サインインページへリダイレクトする" do
        get diaries_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "200 OKを返す" do
        get diaries_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /diaries/:id" do
    let!(:diary) { create(:diary, user: user) }

    before { sign_in user }

    it "自分のdiaryにアクセスできる" do
      get diary_path(diary)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /diaries" do
    before { sign_in user }

    let(:valid_params) do
      { diary: { title: "今日の日記", body: "晴れだった", recorded_on: Date.today, mood: 3 } }
    end

    it "ログインユーザーに紐づくdiaryを作成する" do
      expect {
        post diaries_path, params: valid_params
      }.to change(user.diaries, :count).by(1)
    end

    it "作成したdiaryの詳細ページへリダイレクトする" do
      post diaries_path, params: valid_params
      expect(response).to redirect_to(diary_path(Diary.last))
    end
  end

  describe "GET /diaries/:id/edit" do
    let!(:diary) { create(:diary, user: user) }

    before { sign_in user }

    it "自分のdiaryの編集ページを表示する" do
      get edit_diary_path(diary)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /diaries/:id" do
    let!(:diary) { create(:diary, user: user) }

    before { sign_in user }

    it "自分のdiaryを更新してdiaryの詳細ページへリダイレクトする" do
      patch diary_path(diary), params: { diary: { title: "更新後タイトル" } }
      expect(response).to redirect_to(diary_path(diary))
      expect(diary.reload.title).to eq "更新後タイトル"
    end
  end

  describe "DELETE /diaries/:id" do
    let!(:diary) { create(:diary, user: user) }

    before { sign_in user }

    it "自分のdiaryを削除してdiaryの一覧ページへリダイレクトする" do
      expect {
        delete diary_path(diary)
      }.to change(user.diaries, :count).by(-1)
      expect(response).to redirect_to(diaries_path)
    end
  end
end
