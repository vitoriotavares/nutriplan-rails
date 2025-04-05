class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @anamneses = current_user.anamneses.order(created_at: :desc)
    @food_plans = current_user.food_plans.order(created_at: :desc).limit(5)
  end
end