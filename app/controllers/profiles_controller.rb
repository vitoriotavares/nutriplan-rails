class ProfilesController < ApplicationController
  before_action :authenticate_user!
  
  def show
    @profile = current_user.profile
  end
  
  def edit
    @profile = current_user.profile
  end
  
  def update
    @profile = current_user.profile
    
    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Perfil atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def profile_params
    params.require(:profile).permit(:name, :date_of_birth, :gender, :height, :weight)
  end
end