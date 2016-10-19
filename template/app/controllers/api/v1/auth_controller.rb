class Api::V1::AuthController < Api::BaseController
  access all: {except: [:destroy]}, user: :all 

  api :POST, '/v1/auth', "Login:\n\nLogs user in and creates auth token.\nReturned token should be included in Header as (Authorization: 'a29192kj3j2k39etc'})"
  param :email, String, desc: "email", required: false
  param :password, String, desc: "password", required: false
  example '
  {
    "auth_token": "N0RpNkJkejJNZGZ6cHZKLVBBU3lkdmFkZXJAZm9yY2VfdW5kZXJlc3RpbWF0ZWQuY29t",
    "email": "dvader@force_underestimated.com",
    "id": 5,
    "first_name": "Darth",
    "last_name": "Vader",
    "age": 46,
    "phone": "8778988888",
    "description": "No, I am your father."
  }'
  def create
    if params[:email] && found_user && found_user.valid_password?(auth_params[:password]) #login with email/password
      connection = found_user.api_connections.create  
      render json: {auth_token: connection.token, email: @found_user.email, 
      id: @found_user.id, first_name: @found_user.first_name, last_name: @found_user.last_name, 
      age: @found_user.age, phone: @found_user.phone, description: @found_user.description, image_uri: @found_user.image_uri}.to_json, status: :ok
    else
      render status: :unauthorized, nothing: true
    end
  end


  api :DELETE, "/v1/auth", "Logout"
  def destroy
    @connection.destroy 
    render status: :ok, json: {message: "connection destroyed"}
  end

  api :POST, "/v1/forgot_password"
  param :email, String, required: true
  def forgot_password
    begin
      user = found_user
      user.send_reset_password_instructions
      render status: :ok, json: {note: "password reset instructions sent"}
    rescue => e
      puts e.backtrace
      render status: :unprocessable_entity, nothing: true
    end
  end

  api :POST, "/v1/change_password"
  # TODO: allow authorized user with a valid session to change password. 'token' should not be a required field in this case
  param :token, String, desc: "Token will be sent by email when forgot password is called. (for beta purposes it will also be returned by /forgot_password.)", required: true
  param :password, String, required: true
  param :password_confirmation, String, required: true
  def change_password 
    user = User.find_by(mobile_reset_token: params[:token])
    if user && user.update(password: params[:password], password_confirmation: params[:password_confirmation], mobile_reset_token: nil)
      render status: :ok, json: {message: "Password Changed"}
    else
      render json: {error: "Incorrect token or missmatched password"}, status: :unprocessable_entity
    end
  end

  private
  def auth_params
    params.permit(:email, :password)
  end

  def found_user
    p auth_params[:email]
    @found_user ||= (User.find_by(email: auth_params[:email]))
  end


end

