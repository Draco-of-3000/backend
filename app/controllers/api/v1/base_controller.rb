class Api::V1::BaseController < ActionController::API
  # protect_from_forgery with: :exception # Consider if CSRF protection is needed for API and how to handle
  include ActionController::HttpAuthentication::Token::ControllerMethods # If using token auth

  before_action :set_current_user
  
  private
  
  def set_current_user
    user_id_from_header = request.headers['X-User-ID']
    
    # Allow params[:user_id] for specific actions if header is not present
    # This is useful for scenarios where setting a header might be complex (e.g., initial requests, simple clients)
    # Ensure this aligns with your security model.
    allowed_actions_for_param_auth = %w[create join start_game play_card draw_card] # Added play_card and draw_card
    
    if user_id_from_header.present?
      @current_user = User.find_by(id: user_id_from_header)
    elsif allowed_actions_for_param_auth.include?(action_name) && params[:user_id].present?
      @current_user = User.find_by(id: params[:user_id])
    end
  end

  def deep_to_plain_object(obj)
    case obj
    when Hash
      obj.each_with_object({}) do |(key, value), hash|
        hash[key.to_s] = deep_to_plain_object(value) # Ensure string keys
      end
    when Array
      obj.map { |value| deep_to_plain_object(value) }
    when ActiveSupport::TimeWithZone
      obj.iso8601 # Or obj.to_s
    when GlobalID::Identification # Add this case
      obj.to_global_id.to_s # Convert GlobalID to string
    when ActiveRecord::Base # Add this case for any remaining AR objects
      obj.attributes.stringify_keys.transform_values { |v| deep_to_plain_object(v) }
    else
      obj # Return primitive types as is
    end
  end
  
  def current_user
    @current_user
  end
  
  def authenticate_user!
    render_unauthorized unless current_user
    end
  
  def render_unauthorized
    render json: { success: false, error: 'Authentication required' }, status: :unauthorized
  end
  
  def render_error(message, status = :unprocessable_entity)
    render json: { success: false, error: message }, status: status
  end
  
  def render_success(data = {}, message = nil, status = :ok)
    response_data = { success: true }
    response_data[:message] = message if message.present?
    response_data[:data] = data if data.present?
    render json: response_data, status: status
  end
end 