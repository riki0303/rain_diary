class DiariesController < ApplicationController
  before_action :set_diary, only: %i[show edit update destroy]

  # TODO: 行数が長いアクションに関してリファクタしたい
  def index
    authorize Diary
    scope = policy_scope(Diary)
    @diaries      = scope.includes(:weather_record).order(recorded_on: :desc).page(params[:page])

    coords = location_params
    if coords.nil?
      @rainy_now = nil
      @location_missing = true
    else
      weather_data = WeatherService.new(latitude: coords[0], longitude: coords[1]).fetch!
      @rainy_now = WeatherRecord.rainy?(weather_data[:weather_main])
    end
  rescue WeatherService::RateLimitedError
    flash.now[:alert] = "天気情報を取得できませんでした。しばらく時間を空けてからお試しください。"
    @rainy_now = nil
  rescue WeatherService::Error
    flash.now[:alert] = "天気情報を取得できませんでした。"
    @rainy_now = nil
  end

  def show
    authorize @diary
  end

  def new
    @diary = current_user.diaries.build
    authorize @diary
  end

  def create
    @diary = current_user.diaries.build(diary_params)
    @diary.recorded_on = Date.current # NOTE: 雨の日以外を選択出来ないように日付は固定
    authorize @diary

    coords = location_params
    if coords.nil?
      flash.now[:alert] = "位置情報を許可してください"
      return render :new, status: :unprocessable_entity
    end

    latitude, longitude = coords
    weather_data = WeatherService.new(latitude:, longitude:).fetch!
    @diary.assign_weather(weather_data)

    if @diary.save
      redirect_to @diary, notice: "日記を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  rescue WeatherService::RateLimitedError
    flash.now[:alert] = "天気情報を取得できませんでした。しばらく時間を空けてからお試しください。"
    render :new, status: :unprocessable_entity
  rescue WeatherService::Error
    flash.now[:alert] = "天気情報を取得できませんでした。"
    render :new, status: :unprocessable_entity
  end

  def edit
    authorize @diary
  end

  def update
    authorize @diary
    if @diary.update(diary_params)
      redirect_to @diary, notice: "日記を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @diary
    @diary.destroy
    redirect_to diaries_path, notice: "日記を削除しました。"
  end

  private

  def set_diary
    @diary = policy_scope(Diary).find(params[:id])
  end

  def diary_params
    params.require(:diary).permit(:title, :body, :mood)
  end

  def location_params
    lat = params[:latitude].to_f
    lng = params[:longitude].to_f
    return nil unless valid_coordinates?(lat, lng)

    [ lat, lng ]
  end

  def valid_coordinates?(lat, lng)
    lat.between?(-90, 90) && lng.between?(-180, 180) && (lat != 0.0 || lng != 0.0)
  end
end
