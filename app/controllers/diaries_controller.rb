class DiariesController < ApplicationController
  before_action :set_diary, only: %i[show edit update destroy]

  # TODO: 各アクションの処理をリファクタリングする
  def index
    authorize Diary
    scope = policy_scope(Diary)
    @diaries      = scope.includes(:weather_record).order(recorded_on: :desc).page(params[:page])
    @total_count  = scope.count
    @yearly_count = scope.where(recorded_on: Date.current.all_year).count

    coords = location_params
    if coords.nil?
      @rainy_now = nil
      @location_missing = true
    else
      weather_data = WeatherService.new(latitude: coords[0], longitude: coords[1]).fetch
      if weather_api_error?(weather_data)
        flash.now[:alert] = weather_alert_for(weather_data)
        @rainy_now = nil
      else
        @rainy_now = weather_data.present? && WeatherRecord.rainy?(weather_data[:weather_main])
      end
    end
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

    # TODO: 早期リターン周りをprivateに隠蔽しても良いかも
    coords = location_params
    if coords.nil?
      flash.now[:alert] = "位置情報を許可してください"
      return render :new, status: :unprocessable_entity
    end

    latitude, longitude = coords
    weather_data = WeatherService.new(latitude:, longitude:).fetch
    alert = weather_alert_for(weather_data)
    if alert
      flash.now[:alert] = alert
      return render :new, status: :unprocessable_entity
    end

    if weather_data.blank?
      flash.now[:alert] = "現在の天気が取得できませんでした。しばらく経ってからお試しください"
      return render :new, status: :unprocessable_entity
    end

    @diary.assign_weather(weather_data)

    if @diary.save
      redirect_to @diary, notice: "日記を作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
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

  def weather_api_error?(result)
    result.is_a?(Symbol)
  end

  def weather_alert_for(result)
    case result
    when :rate_limited
      "天気情報を取得できませんでした。しばらく時間を空けてからお試しください。"
    when :server_error
      "天気情報を取得できませんでした。時間をおいて再度お試しください。"
    end
  end

  def location_params
    lat = params[:latitude].to_f
    lng = params[:longitude].to_f
    # TODO: ロジックを切り出す
    return nil unless lat.between?(-90, 90) && lng.between?(-180, 180) && (lat != 0.0 || lng != 0.0)

    [ lat, lng ]
  end
end
