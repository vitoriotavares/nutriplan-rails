class AnamnesesController < ApplicationController
  before_action :require_login
  before_action :set_anamnesis, only: [:show, :edit, :update, :next_step, :previous_step, :generate_plan]
  
  def index
    @anamneses = current_user.anamneses
  end
  
  def show
  end
  
  def new
    @anamnesis = current_user.anamneses.build
    @step = 'health_data'
    render "anamneses/steps/#{@step}"
  end
  
  def create
    @anamnesis = current_user.anamneses.build(anamnesis_params)
    
    if @anamnesis.save
      redirect_to next_step_anamnesis_path(@anamnesis, step: 'health_data'), 
                  notice: I18n.t('app.anamneses.created')
    else
      @step = 'health_data'
      render 'anamneses/steps/health_data', status: :unprocessable_entity
    end
  end
  
  def edit
    @step = params[:step] || 'health_data'
    render "anamneses/steps/#{@step}"
  end
  
  def update
    if @anamnesis.update(anamnesis_params)
      if params[:next_step].present?
        redirect_to next_step_anamnesis_path(@anamnesis, step: params[:step]), 
                    notice: I18n.t('app.anamneses.updated')
      else
        redirect_to anamnesis_path(@anamnesis), 
                    notice: I18n.t('app.anamneses.updated')
      end
    else
      @step = params[:step] || 'health_data'
      render "anamneses/steps/#{@step}", status: :unprocessable_entity
    end
  end
  
  def next_step
    current_step = params[:step]
    @next_step = next_step_for(current_step)
    
    if @next_step == 'complete'
      redirect_to anamnesis_path(@anamnesis)
    else
      redirect_to edit_anamnesis_path(@anamnesis, step: @next_step)
    end
  end
  
  def previous_step
    current_step = params[:step]
    @previous_step = previous_step_for(current_step)
    
    redirect_to edit_anamnesis_path(@anamnesis, step: @previous_step)
  end
  
  def generate_plan
    # Verificar se a anamnese tem as métricas necessárias
    if !has_required_metrics?(@anamnesis)
      redirect_to anamnesis_path(@anamnesis), alert: "Não é possível gerar um plano nutricional sem as métricas básicas. Por favor, complete os dados de saúde."
      return
    end
    
    # Verificar se o usuário pode criar um plano alimentar (limite do plano)
    unless current_user.can_create_food_plan?
      redirect_to anamnesis_path(@anamnesis), alert: "Você atingiu o limite de planos alimentares do seu plano atual."
      return
    end
    
    # Usar o serviço de IA para gerar o plano nutricional
    generator = AiNutritionPlanGenerator.new(@anamnesis)
    @food_plan = generator.generate_plan
    
    if @food_plan.persisted?
      redirect_to food_plan_path(@food_plan), notice: I18n.t('app.food_plans.created')
    else
      redirect_to anamnesis_path(@anamnesis), alert: I18n.t('app.food_plans.create_error')
    end
  end
  
  private
  
  def set_anamnesis
    @anamnesis = current_user.anamneses.find(params[:id])
  end
  
  def anamnesis_params
    # Parâmetros comuns para todas as etapas
    common_params = [:title, :client_name]
    
    # Permitir diferentes parâmetros dependendo da etapa atual
    case params[:step]
    when 'health_data'
      params.require(:anamnesis).permit(
        *common_params,
        health_data: [:height, :weight, :date_of_birth, :gender, :blood_type, :allergies, :medical_conditions, :medications]
      )
    when 'dietary_preferences'
      params.require(:anamnesis).permit(
        *common_params,
        dietary_preferences: [:favorite_foods, :disliked_foods, :meal_frequency, :diet_type]
      )
    when 'restrictions'
      params.require(:anamnesis).permit(
        *common_params,
        restrictions: [:food_allergies, :intolerances, :medical_restrictions]
      )
    when 'lifestyle'
      params.require(:anamnesis).permit(
        *common_params,
        lifestyle: [:activity_level, :exercise_frequency, :occupation, :stress_level, :sleep_hours]
      )
    when 'goals'
      params.require(:anamnesis).permit(
        *common_params,
        goals: [:weight_goal, :health_objectives, :target_date, :specific_needs]
      )
    else
      params.require(:anamnesis).permit(*common_params)
    end
  end
  
  def next_step_for(current_step)
    steps = ['health_data', 'dietary_preferences', 'restrictions', 'lifestyle', 'goals', 'complete']
    current_index = steps.index(current_step)
    
    return 'complete' unless current_index
    
    next_index = current_index + 1
    next_index >= steps.length ? 'complete' : steps[next_index]
  end
  
  def previous_step_for(current_step)
    steps = ['health_data', 'dietary_preferences', 'restrictions', 'lifestyle', 'goals']
    current_index = steps.index(current_step)
    
    return 'health_data' unless current_index
    
    previous_index = current_index - 1
    previous_index < 0 ? 'health_data' : steps[previous_index]
  end
  
  def has_required_metrics?(anamnesis)
    # Verificar se os dados básicos de saúde estão presentes
    return false unless anamnesis.health_data.present?
    
    # Verificar métricas essenciais: altura, peso, data de nascimento e gênero
    required_fields = ['height', 'weight', 'date_of_birth', 'gender']
    required_fields.all? do |field|
      anamnesis.health_data[field].present?
    end
  end
  
  def require_login
    unless current_user
      redirect_to login_path, alert: I18n.t('app.sessions.login_required')
    end
  end
end
