class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, except: [:destroy]
  
  def new
    # Página de login
    redirect_to dashboard_path if logged_in?
  end
  
  def create
    user = User.find_by(email: params[:email])
    
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to dashboard_path, notice: I18n.t('app.sessions.created')
    else
      flash.now[:alert] = I18n.t('app.sessions.invalid')
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: I18n.t('app.sessions.destroyed')
  end
end