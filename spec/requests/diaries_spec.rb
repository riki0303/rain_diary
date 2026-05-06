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

      context "lat/lng クエリなし" do
        it "位置情報許可案内が表示される" do
          get diaries_path
          expect(response.body).to include("位置情報を許可してください")
        end
      end

      context "lat/lng が範囲外の値の場合" do
        it "位置情報許可案内が表示される（無効な座標は nil 扱い）" do
          get diaries_path, params: { latitude: 999, longitude: 999 }
          expect(response.body).to include("位置情報を許可してください")
        end
      end

      context "lat/lng が 0, 0（無効扱い）の場合" do
        it "位置情報許可案内が表示される" do
          get diaries_path, params: { latitude: 0, longitude: 0 }
          expect(response.body).to include("位置情報を許可してください")
        end
      end

      context "lat/lng クエリあり・WeatherService が Rain を返すとき" do
        before do
          allow_any_instance_of(WeatherService).to receive(:fetch).and_return(
            { weather_main: "Rain", city_name: "Tokyo", description: "雨", temp: 15.0, humidity: 80, rainfall_mm: 3.0 }
          )
        end

        it "今日の雨を記録するリンクが表示される" do
          get diaries_path, params: { latitude: 35.68, longitude: 139.65 }
          expect(response.body).to include("今日の雨を記録する")
        end
      end

      context "lat/lng クエリあり・WeatherService が Clear を返すとき" do
        before do
          allow_any_instance_of(WeatherService).to receive(:fetch).and_return(
            { weather_main: "Clear", city_name: "Tokyo", description: "晴れ", temp: 25.0, humidity: 50, rainfall_mm: 0.0 }
          )
        end

        it "今日は雨ではありませんが表示される" do
          get diaries_path, params: { latitude: 35.68, longitude: 139.65 }
          expect(response.body).to include("今日は雨ではありません")
        end
      end

      context "lat/lng クエリあり・WeatherService が nil を返すとき" do
        before { allow_any_instance_of(WeatherService).to receive(:fetch).and_return(nil) }

        it "雨でない表示になる" do
          get diaries_path, params: { latitude: 35.68, longitude: 139.65 }
          expect(response.body).to include("今日は雨ではありません")
        end
      end

      context "lat/lng クエリあり・WeatherService が :rate_limited を返すとき" do
        before { allow_any_instance_of(WeatherService).to receive(:fetch).and_return(:rate_limited) }

        it "レート制限エラーメッセージが表示される" do
          get diaries_path, params: { latitude: 35.68, longitude: 139.65 }
          expect(response.body).to include("しばらく時間を空けて")
        end
      end

      context "lat/lng クエリあり・WeatherService が :server_error を返すとき" do
        before { allow_any_instance_of(WeatherService).to receive(:fetch).and_return(:server_error) }

        it "サーバーエラーメッセージが表示される" do
          get diaries_path, params: { latitude: 35.68, longitude: 139.65 }
          expect(response.body).to include("時間をおいて")
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
  end

  describe "POST /diaries" do
    let(:valid_params) do
      { diary: { title: "今日の日記", body: "晴れだった", mood: 3 }, latitude: 35.68, longitude: 139.65 }
    end

    before do
      sign_in user
      allow_any_instance_of(WeatherService).to receive(:fetch).and_return(
        city_name: "Tokyo", weather_main: "Rain", description: "小雨",
        temp: 14.5, humidity: 82, rainfall_mm: 3.2
      )
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

      it "日記が作成されない" do
        expect {
          post diaries_path, params: valid_params
        }.not_to change(user.diaries, :count)
      end

      it "422 を返す" do
        post diaries_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "天気取得失敗メッセージが表示される" do
        post diaries_path, params: valid_params
        expect(response.body).to include("現在の天気が取得できませんでした")
      end
    end

    context "WeatherService が :rate_limited を返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return(:rate_limited)
      end

      it "422 を返す" do
        post diaries_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "日記が作成されない" do
        expect {
          post diaries_path, params: valid_params
        }.not_to change(user.diaries, :count)
      end

      it "レート制限エラーメッセージが表示される" do
        post diaries_path, params: valid_params
        expect(response.body).to include("しばらく時間を空けて")
      end
    end

    context "WeatherService が :server_error を返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return(:server_error)
      end

      it "422 を返す" do
        post diaries_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "日記が作成されない" do
        expect {
          post diaries_path, params: valid_params
        }.not_to change(user.diaries, :count)
      end

      it "サーバーエラーメッセージが表示される" do
        post diaries_path, params: valid_params
        expect(response.body).to include("時間をおいて")
      end
    end

    context "WeatherService が Clear を返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return(
          city_name: "Tokyo", weather_main: "Clear", description: "晴れ",
          temp: 25.0, humidity: 50, rainfall_mm: 0.0
        )
      end

      it "422 を返す" do
        post diaries_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "日記が作成されない" do
        expect {
          post diaries_path, params: valid_params
        }.not_to change(user.diaries, :count)
      end

      it "雨の日のみメッセージが表示される" do
        post diaries_path, params: valid_params
        expect(response.body).to include("雨の日のみ日記を記録できます")
      end
    end

    context "WeatherService が Drizzle を返す場合" do
      before do
        allow_any_instance_of(WeatherService).to receive(:fetch).and_return(
          city_name: "Tokyo", weather_main: "Drizzle", description: "霧雨",
          temp: 14.0, humidity: 85, rainfall_mm: 1.0
        )
      end

      it "日記作成成功" do
        expect {
          post diaries_path, params: valid_params
        }.to change(user.diaries, :count).by(1)
      end
    end

    context "latitude / longitude が欠落している場合" do
      let(:params_without_location) do
        { diary: { title: "今日の日記", body: "晴れだった", mood: 3 } }
      end

      it "422 Unprocessable Entity を返す" do
        post diaries_path, params: params_without_location
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "日記が作成されない" do
        expect {
          post diaries_path, params: params_without_location
        }.not_to change(user.diaries, :count)
      end

      it "位置情報エラーメッセージが表示される" do
        post diaries_path, params: params_without_location
        expect(response.body).to include("位置情報を許可してください")
      end
    end

    context "latitude / longitude が無効な値（0, 0）の場合" do
      let(:invalid_location_params) do
        { diary: { title: "今日の日記", body: "晴れだった", mood: 3 }, latitude: 0, longitude: 0 }
      end

      it "422 Unprocessable Entity を返す" do
        post diaries_path, params: invalid_location_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "日記が作成されない" do
        expect {
          post diaries_path, params: invalid_location_params
        }.not_to change(user.diaries, :count)
      end
    end

    context "latitude / longitude が範囲外の値の場合" do
      let(:out_of_range_params) do
        { diary: { title: "今日の日記", body: "晴れだった", mood: 3 }, latitude: 999, longitude: 999 }
      end

      it "422 Unprocessable Entity を返す" do
        post diaries_path, params: out_of_range_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "日記が作成されない" do
        expect {
          post diaries_path, params: out_of_range_params
        }.not_to change(user.diaries, :count)
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
