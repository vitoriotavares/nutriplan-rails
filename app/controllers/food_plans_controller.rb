class FoodPlansController < ApplicationController
  before_action :require_login
  before_action :set_food_plan, only: [:show, :edit, :update, :destroy, :generate_pdf]
  
  def index
    @food_plans = current_user.food_plans
  end
  
  def show
    @macros = @food_plan.anamnesis.calculate_macros(@food_plan.calories)
  end
  
  def new
    @anamnesis = current_user.anamneses.find(params[:anamnesis_id]) if params[:anamnesis_id]
    @food_plan = current_user.food_plans.build(anamnesis: @anamnesis)
  end
  
  def create
    @food_plan = current_user.food_plans.build(food_plan_params)
    
    if @food_plan.save
      # Gerar o plano alimentar com o serviço de IA
      generate_nutrition_plan(@food_plan)
      
      redirect_to food_plan_path(@food_plan), notice: I18n.t('app.food_plans.created')
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @food_plan.update(food_plan_params)
      redirect_to food_plan_path(@food_plan), notice: I18n.t('app.food_plans.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @food_plan.destroy
    redirect_to food_plans_path, notice: I18n.t('app.food_plans.destroyed')
  end
  
  def generate_pdf
    # Implementação futura para geração de PDF
    redirect_to food_plan_path(@food_plan), notice: I18n.t('app.food_plans.pdf_generated')
  end
  
  private
  
  def set_food_plan
    @food_plan = current_user.food_plans.find(params[:id])
  end
  
  def food_plan_params
    params.require(:food_plan).permit(:name, :description, :start_date, :end_date, :calories, :anamnesis_id)
  end
  
  # Método para gerar o plano nutricional usando o serviço de IA
  def generate_nutrition_plan(food_plan)
    if food_plan.anamnesis.present?
      begin
        # Usar o serviço de IA para gerar o plano alimentar
        generator = AiNutritionPlanGenerator.new(food_plan.anamnesis)
        
        # Gerar o plano diretamente para o food_plan atual
        generator.generate_plan
        
        # Registrar sucesso no log
        Rails.logger.info("Plano alimentar gerado com sucesso usando IA para o usuário #{current_user.id}")
      rescue => e
        # Registrar erro no log
        Rails.logger.error("Erro ao gerar plano alimentar com IA: #{e.message}")
        
        # Fallback para o método básico em caso de erro
        create_basic_meals(food_plan)
      end
    else
      # Fallback para o método básico caso não haja anamnese
      create_basic_meals(food_plan)
    end
  end
  
  def create_basic_meals(food_plan)
    # Criando refeições padrão
    meals = [
      { name: "Café da Manhã", time: "07:00", meal_type: "breakfast", objective: "Fornecer energia para o início do dia" },
      { name: "Lanche da Manhã", time: "10:00", meal_type: "morning_snack", objective: "Manter o metabolismo ativo" },
      { name: "Almoço", time: "13:00", meal_type: "lunch", objective: "Fornecer nutrientes essenciais" },
      { name: "Lanche da Tarde", time: "16:00", meal_type: "afternoon_snack", objective: "Evitar queda de energia" },
      { name: "Jantar", time: "19:00", meal_type: "dinner", objective: "Recuperação muscular e saciedade" }
    ]
    
    meals.each do |meal_data|
      meal = food_plan.meals.create(meal_data)
      
      # Adicionar alguns itens alimentares básicos a cada refeição
      case meal.meal_type
      when "breakfast"
        meal.food_items.create(name: "Pão integral", quantity: "2", unit: "fatias")
        meal.food_items.create(name: "Ovos", quantity: "2", unit: "unidades")
        meal.food_items.create(name: "Café", quantity: "1", unit: "xícara")
      when "lunch", "dinner"
        meal.food_items.create(name: "Arroz integral", quantity: "4", unit: "colheres de sopa")
        meal.food_items.create(name: "Feijão", quantity: "2", unit: "colheres de sopa")
        meal.food_items.create(name: "Frango grelhado", quantity: "150", unit: "gramas")
        meal.food_items.create(name: "Salada verde", quantity: "1", unit: "prato")
      when "morning_snack", "afternoon_snack"
        meal.food_items.create(name: "Fruta", quantity: "1", unit: "unidade")
        meal.food_items.create(name: "Iogurte natural", quantity: "1", unit: "pote pequeno")
      end
    end
    
    # Criar plano de hidratação
    food_plan.create_water_plan(
      daily_amount: "2000",
      recommendation: "Beber 8 copos de água por dia, distribuídos ao longo do dia."
    )
  end
  
  def require_login
    unless current_user
      redirect_to login_path, alert: I18n.t('app.sessions.login_required')
    end
  end
end
