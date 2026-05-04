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

      context "WeatherService が Rain を返すとき" do
        before do
          allow_any_instance_of(WeatherService).to receive(:fetch).and_return(
            { weather_main: "Rain", city_name: "Tokyo", description: "雨", temp: 15.0, humidity: 80, rainfall_mm: 3.0 }
          )
        end

        it "今日の雨を記録するリンクが表示される" do
          get diaries_path
          expect(response.body).to include("今日の雨を記録する")
        end
      end

      context "WeatherService が Clear を返すとき" do
        before do
          allow_any_instance_of(WeatherService).to receive(:fetch).and_return(
            { weather_main: "Clear", city_name: "Tokyo", description: "晴れ", temp: 25.0, humidity: 50, rainfall_mm: 0.0 }
          )
        end

        it "今日は雨ではありませんが表示される" do
          get diaries_path
          expect(response.body).to include("今日は雨ではありません")
        end
      end

      context "WeatherService が nil を返すとき" do
        before { allow_any_instance_of(WeatherService).to receive(:fetch).and_return(nil) }

        it "雨でない表示になる" do
          get diaries_path
          expect(response.body).to include("今日は雨ではありません")
        end
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

    it "戻るボタンが描画される" do
      get diary_path(diary)
      expect(response.body).to include("戻る")
    end

    it "編集アイコンが描画される" do
      get diary_path(diary)
      expect(response.body).to include("bi-pencil")
    end

    it "削除アイコンが描画される" do
      get diary_path(diary)
      expect(response.body).to include("bi-trash")
    end

    it "ミートボールメニュー（三点リーダー）が描画される" do
      get diary_path(diary)
      expect(response.body).to include("bi-three-dots-vertical")
    end

    it "ドロップダウンメニュー要素が描画される" do
      get diary_path(diary)
      expect(response.body).to include("dropdown-menu")
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

    context "WeatherService が天気データを返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return(
          city_name: "Tokyo", weather_main: "Rain", description: "小雨",
          temp: 14.5, humidity: 82, rainfall_mm: 3.2
        )
      end

      it "weather_records が1件増加する" do
        expect {
          post diaries_path, params: valid_params
        }.to change(WeatherRecord, :count).by(1)
      end
    end

    context "WeatherService が nil を返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return(nil)
      end

      it "日記は作成されるが weather_records は増えない" do
        expect {
          post diaries_path, params: valid_params
        }.to change(user.diaries, :count).by(1)
        expect(WeatherRecord.count).to eq(0)
      end
    end
  end

  describe "GET /diaries/new" do
    before { sign_in user }

    it "戻るボタンが描画される" do
      get new_diary_path
      expect(response.body).to include("戻る")
    end
  end

  describe "GET /diaries/:id/edit" do
    let!(:diary) { create(:diary, user: user) }

    before { sign_in user }

    it "自分のdiaryの編集ページを表示する" do
      get edit_diary_path(diary)
      expect(response).to have_http_status(:ok)
    end

    it "戻るボタンが描画される" do
      get edit_diary_path(diary)
      expect(response.body).to include("戻る")
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

  context "他人の日記に対するアクセス" do
    let(:other_user)   { create(:user) }
    let!(:other_diary) { create(:diary, user: other_user) }

    before { sign_in user }

    it "認可違反となり root_path へリダイレクトされる" do
      get diary_path(other_diary)
      expect(response).to redirect_to(root_path)
    end
  end
end
