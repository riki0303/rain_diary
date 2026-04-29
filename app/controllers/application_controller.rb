class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def user_not_authorized
    flash[:alert] = "この操作は許可されていません。"
    redirect_back fallback_location: root_path
  end

  def record_not_found
    flash[:alert] = "指定されたリソースは見つかりません。"
    redirect_to root_path
  end
end
