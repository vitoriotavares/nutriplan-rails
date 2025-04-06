class UsersController < ApplicationController
  skip_before_action :authenticate_user!
  
  def new
    @user = User.new
    redirect_to dashboard_path if logged_in?
  end
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      # Criar um perfil para o usuário com o nome fornecido
      @user.create_profile(name: params[:user][:name].presence || "Novo Usuário")
      
      # Associar o plano gratuito por padrão
      free_plan = Plan.where(price: 0, is_default: true).first
      if free_plan
        @user.subscriptions.create(
          plan: free_plan,
          status: 'active',
          current_period_start: Time.current,
          current_period_end: 1.month.from_now,
          auto_renew: true
        )
      end
      
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