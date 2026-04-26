# RainDiary 実装仕様書

## アプリ概要

OpenWeatherAPIを使用して、雨の日の記録を残す日記アプリ。
日記を書いた時点の天気データをAPIから自動取得して一緒に保存する。
**雨の日にしか記録できない**特別感を持たせる。

コンセプト：「雨が降るたびに、ページが増える。」

### MVPの位置情報方針

- MVPでは**東京固定**（緯度: 35.6762 / 経度: 139.6503）
- ジオコーディングAPIは使用しない
- 将来的にはGeolocation API（ブラウザの位置情報）または居住地の事前入力に対応予定

### 将来の位置情報設計（MVP後）

1. ブラウザのGeolocation APIで緯度経度を取得（ユーザーが許可した場合）
2. 許可されない場合はユーザーが居住地（都市名）を事前入力
3. 居住地をGeocoding APIで緯度経度に変換してWeather APIへリクエスト

---

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| フレームワーク | Ruby on Rails |
| フロントエンド | Hotwire（Turbo + Stimulus） |
| 認証 | Devise |
| 認可 | Pundit |
| テンプレートエンジン | Haml |
| フォームヘルパー | simple_form |
| ページネーション | Kaminari |
| CSSフレームワーク | Bootstrap（`--css=bootstrap` オプションで導入） |
| DB | PostgreSQL |
| テスト | RSpec |
| HTTPクライアント | Faraday |
| 環境変数管理 | dotenv-rails |

---

## Gemfile

```ruby
gem 'devise'
gem 'pundit'
gem 'haml-rails'
gem 'simple_form'
gem 'kaminari'
gem 'faraday'
gem 'dotenv-rails'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
end
```

---

## DB設計

### usersテーブル（Deviseが自動生成）

| カラム名 | 型 | 制約 |
|---|---|---|
| id | integer | PK |
| email | string | NOT NULL, UNIQUE |
| encrypted_password | string | NOT NULL |
| created_at | datetime | |
| updated_at | datetime | |

### diariesテーブル

| カラム名 | 型 | 制約 | 説明 |
|---|---|--|---|
| id | integer | PK | |
| user_id | integer | NOT NULL, FK | |
| title | string | NOT NULL | 記録のタイトル |
| body | text | NOT NULL | 本文 |
| mood | integer | NOT NULL | 気分（1〜5） |
| recorded_on | date | NOT NULL | 記録した日付 |
| created_at | datetime | | |
| updated_at | datetime | | |

### weather_recordsテーブル

| カラム名 | 型 | 制約 | 説明 |
|---|---|---|---|
| id | integer | PK | |
| diary_id | integer | NOT NULL, FK | |
| city_name | string | NOT NULL | 都市名 |
| weather_main | string | NOT NULL | 天気種別（"Rain"など） |
| description | string | NULL可 | 天気の説明（"小雨"など） |
| temp | float | NULL可 | 気温（℃） |
| humidity | integer | NULL可 | 湿度（%） |
| rainfall_mm | float | NULL可 | 降水量（mm） |
| created_at | datetime | | |
| updated_at | datetime | | |

---

## アソシエーション

```ruby
# User
has_many :diaries, dependent: :destroy

# Journal
belongs_to :user
has_one :weather_record, dependent: :destroy

# WeatherRecord
belongs_to :diary
```

---

## マイグレーション

```ruby
# journals
create_table :diaries do |t|
  t.references :user,        null: false, foreign_key: true
  t.string     :title,       null: false
  t.text       :body,        null: false
  t.integer    :mood
  t.date       :recorded_on, null: false
  t.timestamps
end

# weather_records
create_table :weather_records do |t|
  t.references :diary,      null: false, foreign_key: true
  t.string     :city_name,    null: false
  t.string     :weather_main, null: false
  t.string     :description
  t.float      :temp
  t.integer    :humidity
  t.float      :rainfall_mm
  t.timestamps
end
```

---

## モデル

### Journal

```ruby
class Diary < ApplicationRecord
  belongs_to :user
  has_one :weather_record, dependent: :destroy

  validates :title,       presence: true
  validates :body,        presence: true
  validates :recorded_on, presence: true
end
```

### WeatherRecord

```ruby
class WeatherRecord < ApplicationRecord
  belongs_to :diary

  validates :city_name,    presence: true
  validates :weather_main, presence: true
end
```

---

## ルーティング

```ruby
Rails.application.routes.draw do
  devise_for :users
  root "diaries#index"
  resources :diaries, only: [:index, :show, :new, :create, :edit, :update, :destroy]
end
```

---

## コントローラー

### JournalsController

```ruby
class DiariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_diary, only: [:show, :edit, :update, :destroy]

  def index
    @diaries = current_user.diaries
                            .includes(:weather_record)
                            .order(recorded_on: :desc)
                            .page(params[:page])

    # 一覧表示時に天気を自動取得
    @weather  = WeatherService.new.fetch
    @is_rainy = %w[Rain Drizzle].include?(@weather[:weather_main])
  end

  def show
  end

  def new
    @diary = Journal.new
  end

  def create
    @diary = current_user.diaries.build(diary_params)
    if @diary.save
      attach_weather!
      redirect_to @diary, notice: "記録しました 🌧"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @diary.update(diary_params)
      redirect_to @diary, notice: "更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @diary.destroy
    redirect_to diaries_path, notice: "削除しました"
  end

  private

  def set_diary
    @diary = current_user.diaries.find(params[:id])
  end

  def diary_params
    params.require(:diary).permit(:title, :body, :mood, :recorded_on)
  end

  def attach_weather!
    weather_data = WeatherService.new.fetch
    @diary.create_weather_record!(weather_data)
  rescue => e
    Rails.logger.error("天気取得失敗: #{e.message}")
  end
end
```

---

## サービスクラス

### WeatherService

MVPでは東京固定（緯度・経度をハードコード）。ジオコーディングAPIは使用しない。

```ruby
# app/services/weather_service.rb
class WeatherService
  BASE_URL  = "https://api.openweathermap.org/data/2.5/weather"

  # MVP: 東京固定
  TOKYO_LAT = 35.6762
  TOKYO_LON = 139.6503

  def initialize
    @api_key = ENV["OPENWEATHER_API_KEY"]
  end

  def fetch
    get_weather(TOKYO_LAT, TOKYO_LON)
  end

  private

  def get_weather(lat, lon)
    response = Faraday.get(BASE_URL, {
      lat:   lat,
      lon:   lon,
      appid: @api_key,
      units: "metric",
      lang:  "ja"
    })
    parse(response.body)
  end

  def parse(body)
    data = JSON.parse(body)
    {
      city_name:    data["name"],
      weather_main: data["weather"][0]["main"],
      description:  data["weather"][0]["description"],
      temp:         data["main"]["temp"],
      humidity:     data["main"]["humidity"],
      rainfall_mm:  data.dig("rain", "1h")
    }
  end
end
```

### キャッシュについて（MVP後に追加予定）

```
APIリクエストの節約のため、将来的にRailsキャッシュで30分間レスポンスを保持する。
東京の天気は全ユーザー共通なのでキャッシュが適切。

Rails.cache.fetch("weather_tokyo", expires_in: 30.minutes) do
  get_weather(TOKYO_LAT, TOKYO_LON)
end

将来ユーザーごとに都市が変わる場合はキャッシュキーを都市名で分ける。
Rails.cache.fetch("weather_#{city_name}", expires_in: 30.minutes) { ... }
```

---

## Punditポリシー

```ruby
# app/policies/diary_policy.rb
class DiaryPolicy < ApplicationPolicy
  def show?    = record.user == user
  def edit?    = record.user == user
  def update?  = record.user == user
  def destroy? = record.user == user
end
```

---

## ビュー構成（Haml）

### 一覧（diaries/index.html.haml）

- ページ表示時に自動で東京の天気を取得し、雨かどうかを判定
- 雨（Rain / Drizzle）なら天気情報と「今日の雨を記録する」ボタンを表示
- 雨でなければ「今日は雨ではありません」と表示し、ボタンは非表示
- 記録の総数・今年の件数をカード表示
- 日記一覧をカード形式で表示（記録日、タイトル、本文の冒頭、気分、天気情報）
- Kaminariでページネーション

### フォーム（diaries/_form.html.haml）

simple_formを使用。以下のフィールドを含む（city_nameは不要）。

- recorded_on（日付）
- title（テキスト）
- body（テキストエリア）
- mood（セレクト、1〜5）

### 詳細（diaries/show.html.haml）

- タイトル、記録日、本文を表示
- weather_recordが存在する場合は天気情報を表示（天気、気温、湿度、降水量）
- 気分をドット表示
- 編集・削除リンク

---

## 環境変数

```bash
# .env
OPENWEATHER_API_KEY=your_api_key_here
```

`.gitignore` に `.env` を追加すること。

---

## セットアップ手順

```bash
# Bootstrapを組み込んだ状態でPostgreSQLを指定してプロジェクト作成
rails new rain_diary --css=bootstrap --database=postgresql
cd rain_diary

# DBの作成
rails db:create

# Gemfileを編集後
bundle install

# Deviseセットアップ
rails generate devise:install
rails generate devise User

# モデル生成
rails generate model Diary user:references title:string body:text mood:integer recorded_on:date
rails generate model WeatherRecord diary:references city_name:string weather_main:string description:string temp:float humidity:integer rainfall_mm:float

# マイグレーション実行
rails db:migrate

# simple_formのBootstrap対応インストール
rails generate simple_form:install --bootstrap

# Punditインストール
rails generate pundit:install

# RSpecインストール
rails generate rspec:install
```

---

## 補足事項

- 雨の日（weather_main が "Rain" または "Drizzle"）にしか記録できない。
- 天気取得はdiary保存後に行う。API失敗時も日記は保存する。
- `weather_records` はユーザーが直接操作しない。journalを経由して作成される。
- 認可（Pundit）は `current_user.diaries.find` によるスコープでも担保しているが、ポリシークラスも実装すること。
- 画像アップロードはMVPスコープ外。後から Active Storage で追加予定。
- 位置情報はMVPでは東京固定。将来的にGeolocation APIまたは居住地入力に対応予定。
- APIリクエストのキャッシュはMVPスコープ外。後からRailsキャッシュで対応予定。
