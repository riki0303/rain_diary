class DiariesController < ApplicationController
  before_action :set_diary, only: %i[show edit update destroy]

  def index
    scope = policy_scope(Diary)
    @diaries      = scope.includes(:weather_record).order(recorded_on: :desc).page(params[:page])
    @total_count  = scope.count
    @yearly_count = scope.where(recorded_on: Date.current.all_year).count

    weather    = WeatherService.new.fetch
    @rainy_now = weather.present? && WeatherRecord.rainy_main?(weather[:weather_main])
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
    authorize @diary
    if @diary.save
      @diary.attach_weather!
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
    params.require(:diary).permit(:title, :body, :recorded_on, :mood)
  end
end
