class Api::V1::UsersController < Api::V1::BaseController
  def create
    # Find an existing user or initialize a new one
    @user = User.find_or_initialize_by(username: user_params[:username])
    
    if @user.new_record? # If it's a new user, try to save
      if @user.save
        render_success({ user: user_data(@user) }, 'User created successfully')
      else
        render_error(@user.errors.full_messages.join(', '))
      end
    else # If user already exists, just render the user data
      render_success({ user: user_data(@user) }, 'User found successfully')
    end
  end
  
  def show
    user = User.find_by(id: params[:id])
    
    if user
      render_success({ user: user_data(user) })
    else
      render_error('User not found', :not_found)
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:username)
  end
  
  def user_data(user)
    {
      id: user.id,
      username: user.username,
      created_at: user.created_at
    }
  end
end 