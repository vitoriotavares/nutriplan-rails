class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  
  def index
    # Página inicial do site
    @title = "NutriPlan - Planos Alimentares Personalizados"
  end
end