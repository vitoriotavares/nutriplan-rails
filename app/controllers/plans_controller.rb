class PlansController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :compare]
  
  def index
    @plans = Plan.active.order(price: :asc)
    @current_plan = current_user&.current_plan
  end
  
  def show
    @plan = Plan.find(params[:id])
    @current_plan = current_user.current_plan
    @subscription = current_user.subscriptions.find_by(plan: @plan)
  end
  
  def compare
    @plans = Plan.active.order(price: :asc)
    @current_plan = current_user&.current_plan
  end
end
