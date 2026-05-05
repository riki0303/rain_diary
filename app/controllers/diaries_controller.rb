class DiariesController < ApplicationController
  before_action :set_diary, only: %i[show edit update destroy]

  def index
    scope = policy_scope(Diary)
    @diaries      = scope.includes(:weather_record).order(recorded_on: :desc).page(params[:page])
    @total_count  = scope.count
    @yearly_count = scope.where(recorded_on: Date.current.all_year).count

    coords = location_params
    if coords
      weather    = WeatherService.new(latitude: coords[0], longitude: coords[1]).fetch
      @rainy_now = weather.present? && WeatherRecord.rainy?(weather[:weather_main])
    else
      @rainy_now = nil
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

    coords = location_params
    if coords.nil?
      flash.now[:alert] = "位置情報を許可してください"
      return render :new, status: :unprocessable_entity
    end

    latitude  = coords[0]
    longitude = coords[1]

    if @diary.save
      @diary.attach_weather!(latitude:, longitude:)
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

  def location_params
    lat = params[:latitude].to_f
    lng = params[:longitude].to_f
    # TODO: ロジックを切り出す
    return nil unless lat.between?(-90, 90) && lng.between?(-180, 180) && (lat != 0.0 || lng != 0.0)

    [ lat, lng ]
  end
end
