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
    @food_plan.build_water_plan unless @food_plan.water_plan
  end
  
  def update
    respond_to do |format|
      if @food_plan.update(food_plan_params)
        format.html { redirect_to food_plan_path(@food_plan), notice: I18n.t('app.food_plans.updated') }
        format.turbo_stream { flash.now[:notice] = I18n.t('app.food_plans.updated') }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @food_plan.destroy
    redirect_to food_plans_path, notice: I18n.t('app.food_plans.destroyed')
  end
  
  def generate_pdf
    # Gerar o PDF usando o novo serviço
    pdf_generator = FoodPlanPdfGenerator.new(@food_plan)
    pdf = pdf_generator.generate
    
    # Enviar o arquivo para download
    send_data pdf.render, 
              filename: "plano_alimentar_#{@food_plan.anamnesis.user.profile&.name.to_s.parameterize || 'cliente'}_#{Date.today.strftime('%d_%m_%Y')}.pdf", 
              type: 'application/pdf', 
              disposition: 'attachment'
  end
  
  private
  
  def set_food_plan
    @food_plan = current_user.food_plans.find(params[:id])
  end
  
  def food_plan_params
    params.require(:food_plan).permit(:name, :description, :start_date, :end_date, :calories, :anamnesis_id,
      meals_attributes: [:id, :name, :time, :meal_type, :objective, :_destroy,
        food_items_attributes: [:id, :name, :quantity, :unit, :_destroy,
          substitutes: [:name, :quantity, :unit]
        ]
      ],
      water_plan_attributes: [:id, :daily_amount, :recommendation]
    )
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
  
  def add_cover_page(pdf, food_plan)
    # Definir cores
    primary_color = "8B2635"
    secondary_color = "2C7D54"
    
    # Adicionar fundo decorativo
    pdf.canvas do
      # Borda superior
      pdf.fill_color primary_color
      pdf.fill_rectangle [0, pdf.bounds.height], pdf.bounds.width, 40
      
      # Borda inferior
      pdf.fill_color secondary_color
      pdf.fill_rectangle [0, 40], pdf.bounds.width, 40
      
      # Elementos decorativos
      pdf.fill_color primary_color
      pdf.fill_circle [50, pdf.bounds.height - 100], 30
      pdf.fill_color secondary_color
      pdf.fill_circle [pdf.bounds.width - 50, 100], 30
    end
    
    # Adicionar logo (substitua pelo caminho real do seu logo)
    # pdf.image "#{Rails.root}/app/assets/images/logo.png", at: [pdf.bounds.width/2 - 50, pdf.bounds.height - 100], width: 100
    
    # Título principal
    pdf.move_down 150
    pdf.font("Helvetica", style: :bold) do
      pdf.text "NUTRIPLAN", align: :center, size: 40
      pdf.move_down 20
      pdf.text "PLANO ALIMENTAR", align: :center, size: 30
    end
    
    # Informações do cliente
    pdf.move_down 100
    pdf.font("Helvetica") do
      pdf.text "Cliente: #{food_plan.user.name}", align: :center, size: 18
      pdf.move_down 10
      pdf.text "Data: #{Date.today.strftime('%d/%m/%Y')}", align: :center, size: 14
    end
    
    # Adicionar nova página para o conteúdo
    pdf.start_new_page
  end
  
  def add_plan_info(pdf, food_plan)
    pdf.font("Helvetica", style: :bold) do
      pdf.text "INFORMAÇÕES DO PLANO", size: 16
    end
    
    pdf.move_down 10
    
    # Informações básicas
    pdf.font("Helvetica") do
      pdf.text "Cliente: #{food_plan.user.name}"
      pdf.text "Idade: #{calculate_age(food_plan.anamnesis.birth_date)}"
      pdf.text "Peso: #{food_plan.anamnesis.weight} kg"
      pdf.text "Altura: #{food_plan.anamnesis.height} cm"
      pdf.text "Objetivo: #{food_plan.anamnesis.objective}"
      
      if food_plan.anamnesis.dietary_restrictions.present?
        pdf.move_down 5
        pdf.text "Restrições alimentares: #{food_plan.anamnesis.dietary_restrictions.join(', ')}"
      end
      
      if food_plan.anamnesis.dietary_preferences.present?
        pdf.move_down 5
        pdf.text "Preferências alimentares: #{food_plan.anamnesis.dietary_preferences.values.join(', ')}"
      end
    end
    
    pdf.move_down 20
  end
  
  def add_meals(pdf, food_plan)
    food_plan.meals.order(:time).each do |meal|
      pdf.font("Helvetica", style: :bold) do
        pdf.text meal.name, size: 14
      end
      
      pdf.font("Helvetica", style: :italic) do
        pdf.text "Horário: #{meal.time}", size: 10
        pdf.text "Objetivo: #{meal.objective}", size: 10
      end
      
      pdf.move_down 10
      
      # Adicionar itens alimentares
      meal.food_items.each do |item|
        pdf.font("Helvetica") do
          pdf.text "• #{item.name} - #{item.quantity} #{item.unit}", size: 12
          
          # Adicionar substitutos se existirem
          if item.has_substitutes?
            pdf.indent(15) do
              pdf.font("Helvetica", style: :italic) do
                pdf.text "Opções de substituição:", size: 10
                item.substitutes.each do |substitute|
                  pdf.text "- #{substitute[:name]} - #{substitute[:quantity]} #{substitute[:unit]}", size: 10
                end
              end
            end
          end
        end
        
        pdf.move_down 5
      end
      
      pdf.move_down 15
    end
  end
  
  def calculate_age(birth_date)
    return nil unless birth_date
    
    now = Date.today
    age = now.year - birth_date.year
    
    # Ajustar se ainda não fez aniversário este ano
    age -= 1 if now < birth_date + age.years
    
    age
  end
  
  def require_login
    unless current_user
      redirect_to login_path, alert: I18n.t('app.sessions.login_required')
    end
  end
end
