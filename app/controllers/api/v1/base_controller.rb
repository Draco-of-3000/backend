class Api::V1::BaseController < ApplicationController
  before_action :set_current_user
  
  private
  
  def set_current_user
    user_id = request.headers['X-User-ID']
    # For MVP: If header is not present, try to get user_id from params for relevant actions
    user_id ||= params[:user_id] if params[:user_id].present? && 
                                     (action_name == 'create' || action_name == 'join' || action_name == 'start_game')

    @current_user = User.find_by(id: user_id) if user_id
  end
  
  def current_user
    @current_user
  end
  
  def authenticate_user!
    unless current_user
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end
  
  def render_error(message, status = :unprocessable_entity)
    render json: { error: message }, status: status
  end
  
  def render_success(data = {}, message = nil)
    response = { success: true }
    response[:message] = message if message
    response[:data] = data unless data.empty?
    render json: response
  end
end 