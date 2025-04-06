class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!
  
  def terms
    @title = "Termos de Uso - NutriPlan"
  end
  
  def privacy
    @title = "Política de Privacidade - NutriPlan"
  end
  
  def contact
    @title = "Contato - NutriPlan"
  end
end
