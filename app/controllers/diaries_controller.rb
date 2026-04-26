class DiariesController < ApplicationController
  before_action :set_diary, only: %i[show edit update destroy]

  def index
    @diaries = policy_scope(Diary).order(recorded_on: :desc)
    # TODO: Issue #5 完了後、WeatherService で天気・雨判定を取得
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
      # TODO: Issue #5 完了後、@diary.attach_weather!（API失敗時も日記は保存済み）
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
    @diary = Diary.find(params[:id])
  end

  def diary_params
    params.require(:diary).permit(:title, :body, :recorded_on, :mood)
  end
end
