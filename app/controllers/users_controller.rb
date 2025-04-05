class UsersController < ApplicationController
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      # Criar um perfil vazio para o usuário
      @user.create_profile(name: "Novo Usuário")
      
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: I18n.t('app.users.created')
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end