class AiNutritionPlanGenerator
  attr_reader :anamnesis, :user

  def initialize(anamnesis)
    @anamnesis = anamnesis
    Rails.logger.info("Inicializando AiNutritionPlanGenerator para anamnese ##{anamnesis.id}")
    @user = anamnesis.user
  end

  def generate_plan
    Rails.logger.info("Iniciando geração de plano alimentar para anamnese ##{@anamnesis.id}")
    
    # Criar o plano alimentar base
    food_plan = create_food_plan
    Rails.logger.info("Plano alimentar base criado com ID ##{food_plan.id}")
    
    # Gerar o plano alimentar usando a API da OpenAI
    begin
      Rails.logger.info("Gerando plano alimentar com IA")
      generate_ai_plan(food_plan)
    rescue => e
      Rails.logger.error("Erro ao gerar plano com IA: #{e.message}")
      Rails.logger.info("Usando método de fallback para criar refeições")
      # Fallback para o método antigo caso ocorra algum erro
      create_meals(food_plan)
    end
    
    # Criar plano de hidratação
    create_water_plan(food_plan)
    
    # Retornar o plano alimentar completo
    Rails.logger.info("Plano alimentar gerado com sucesso")
    food_plan
  end

  private

  def generate_ai_plan(food_plan)
    # Limpar refeições existentes antes de criar novas
    food_plan.meals.destroy_all if food_plan.meals.any?
    
    # Criar o prompt para a API da OpenAI
    prompt = build_openai_prompt(food_plan)
    
    # Chamar a API da OpenAI
    begin
      Rails.logger.info("Chamando API da OpenAI para gerar plano alimentar")
      response = call_openai_api(prompt)
      
      # Processar a resposta e criar as refeições
      process_openai_response(response, food_plan)
    rescue => e
      Rails.logger.error("Erro ao chamar a API da OpenAI: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      # Fallback para o método antigo caso ocorra algum erro
      create_meals(food_plan)
    end
  end
  
  def build_openai_prompt(food_plan)
    anamnesis = food_plan.anamnesis
    
    # Dados básicos do paciente
    patient_data = "Dados do Paciente:\n"
    patient_data += "- Nome: #{anamnesis.user.name rescue 'Não informado'}\n"
    patient_data += "- Idade: #{anamnesis.age || 'Não informada'} anos\n"
    patient_data += "- Sexo: #{anamnesis.gender || 'Não informado'}\n"
    patient_data += "- Peso: #{anamnesis.weight || 'Não informado'} kg\n"
    patient_data += "- Altura: #{anamnesis.height || 'Não informada'} cm\n"
    patient_data += "- IMC: #{anamnesis.bmi || 'Não calculado'}\n"
    patient_data += "- Objetivo: #{anamnesis.weight_goal || 'Não informado'}\n"
    
    # Dados de saúde
    health_data = "Dados de Saúde:\n"
    health_data += "- Condições de saúde: #{anamnesis.medical_conditions || 'Nenhuma informada'}\n"
    health_data += "- Medicamentos: #{anamnesis.medications || 'Nenhum informado'}\n"
    health_data += "- Alergias: #{anamnesis.allergies || 'Nenhuma informada'}\n"
    
    # Preferências alimentares
    food_preferences = "Preferências Alimentares:\n"
    food_preferences += "- Alimentos favoritos: #{anamnesis.favorite_foods || 'Nenhum informado'}\n"
    food_preferences += "- Alimentos que não gosta: #{anamnesis.disliked_foods || 'Nenhum informado'}\n"
    
    # Restrições alimentares
    food_restrictions = "Restrições Alimentares:\n"
    food_restrictions += "- Intolerâncias: #{anamnesis.intolerances || 'Nenhuma informada'}\n"
    food_restrictions += "- Restrições: #{anamnesis.medical_restrictions || 'Nenhuma informada'}\n"
    food_restrictions += "- Alergias alimentares: #{anamnesis.food_allergies || 'Nenhuma informada'}\n"
    
    # Estilo de vida
    lifestyle = "Estilo de Vida:\n"
    lifestyle += "- Ocupação: #{anamnesis.occupation || 'Não informada'}\n"
    lifestyle += "- Nível de atividade: #{anamnesis.activity_level || 'Não informado'}\n"
    lifestyle += "- Frequência de exercícios: #{anamnesis.exercise_frequency || 'Não informada'}\n"
    
    # Objetivos específicos
    specific_objectives = "Objetivos Específicos:\n"
    specific_objectives += "- Objetivo principal: #{anamnesis.weight_goal || 'Não informado'}\n"
    specific_objectives += "- Objetivos de saúde: #{anamnesis.health_objectives || 'Não informados'}\n"
    specific_objectives += "- Necessidades específicas: #{anamnesis.specific_needs || 'Nenhuma informada'}\n"
    
    # Necessidades nutricionais
    nutritional_needs = "Necessidades Nutricionais:\n"
    nutritional_needs += "- Calorias diárias: #{food_plan.calories || 'Não calculadas'} kcal\n"
    
    macros = anamnesis.calculate_macros(food_plan.calories)
    if macros
      nutritional_needs += "- Proteínas: #{macros[:protein]}g (#{macros[:protein_percentage]}%)\n"
      nutritional_needs += "- Gorduras: #{macros[:fat]}g (#{macros[:fat_percentage]}%)\n"
      nutritional_needs += "- Carboidratos: #{macros[:carbs]}g (#{macros[:carb_percentage]}%)\n"
    end
    
    # Instruções para o formato da resposta
    response_format = <<~FORMAT
    Instruções para o Formato da Resposta:
    
    Crie um plano alimentar personalizado para este paciente com 6 refeições diárias: Café da Manhã, Lanche da Manhã, Almoço, Lanche da Tarde, Jantar e Ceia.
    
    Responda APENAS no seguinte formato JSON:
    
    {
      "meals": [
        {
          "name": "Nome da Refeição (ex: Café da Manhã)",
          "time": "Horário (ex: 07:30)",
          "objective": "Objetivo desta refeição",
          "foods": [
            {
              "name": "Nome do Alimento",
              "quantity": "Quantidade (ex: 100)",
              "unit": "Unidade (ex: g, ml, colher de sopa)"
            },
            ...mais alimentos
          ]
        },
        ...mais refeições
      ]
    }
    
    Importante:
    - Inclua exatamente 6 refeições
    - Cada refeição deve ter pelo menos 3 alimentos
    - Respeite as preferências e restrições alimentares do paciente
    - Forneça quantidades precisas para cada alimento
    - Use unidades de medida claras (g, ml, colher de sopa, etc.)
    - Não inclua comentários ou texto adicional fora do formato JSON
    FORMAT
    
    # Montar o prompt completo
    prompt = <<~PROMPT
    #{patient_data}
    
    #{health_data}
    
    #{food_preferences}
    
    #{food_restrictions}
    
    #{lifestyle}
    
    #{specific_objectives}
    
    #{nutritional_needs}
    
    #{response_format}
    PROMPT
    
    prompt
  end
  
  def call_openai_api(prompt)
    begin
      client = OpenAI::Client.new
      response = client.chat(
        parameters: {
          model: "gpt-4o", # Usando o modelo mais recente da OpenAI
          messages: [
            { role: "system", content: "Você é um nutricionista especializado em criar planos alimentares personalizados. Responda no formato JSON com a estrutura: { \"meals\": [ { \"name\": \"Nome da Refeição\", \"time\": \"HH:MM\", \"objective\": \"Objetivo\", \"foods\": [ { \"name\": \"Nome do Alimento\", \"quantity\": \"Quantidade\", \"unit\": \"Unidade\" } ] } ] }" },
            { role: "user", content: prompt }
          ],
          temperature: 0.7,
          max_tokens: 2000,
          top_p: 1.0,
          frequency_penalty: 0.0,
          presence_penalty: 0.0,
          response_format: { "type": "json_object" }
        }
      )
      
      # Verificar se a resposta contém o conteúdo esperado
      content = response.dig("choices", 0, "message", "content")
      
      if content.nil? || content.empty?
        Rails.logger.error("Resposta vazia da API da OpenAI")
        raise "Resposta vazia da API da OpenAI"
      end
      
      # Verificar se a resposta está no formato JSON esperado
      begin
        json_response = JSON.parse(content)
        unless json_response.is_a?(Hash) && json_response.key?("meals") && json_response["meals"].is_a?(Array)
          Rails.logger.error("Resposta da API da OpenAI não está no formato JSON esperado")
          raise "Resposta da API da OpenAI não está no formato JSON esperado"
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Resposta da API da OpenAI não está no formato JSON: #{e.message}")
        raise "Resposta da API da OpenAI não está no formato JSON"
      end
      
      Rails.logger.info("Resposta da API da OpenAI recebida com sucesso")
      content
    rescue => e
      Rails.logger.error("Erro ao chamar a API da OpenAI: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      raise e
    end
  end
  
  def process_openai_response(response, food_plan)
    begin
      Rails.logger.info("Processando resposta da API da OpenAI")
      
      # Salvar a resposta original da API para avaliação futura
      food_plan.update(ai_response: response)
      
      # Garantir que o food_plan está salvo antes de continuar
      unless food_plan.persisted?
        Rails.logger.error("Food plan não está salvo, salvando agora...")
        food_plan.save!
      end
      
      # Limpar código markdown se presente
      cleaned_response = response.gsub(/```json\s*/, '').gsub(/```\s*/, '')
      
      # Tentar processar como JSON primeiro
      begin
        json_response = JSON.parse(cleaned_response)
        if json_response.key?("meals")
          process_json_response(json_response, food_plan)
          return
        end
      rescue JSON::ParserError => e
        Rails.logger.info("Resposta não está em formato JSON, processando como texto: #{e.message}")
      end
      
      # Se não for JSON, processar como texto estruturado
      process_text_response(cleaned_response, food_plan)
    rescue => e
      Rails.logger.error("Erro ao processar resposta da OpenAI: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
      # Fallback para o método básico em caso de erro
      create_meals(food_plan)
    end
  end
  
  def process_json_response(json_response, food_plan)
    Rails.logger.info("Processando resposta JSON da API da OpenAI")
    
    # Limpar refeições existentes
    food_plan.meals.destroy_all
    
    # Criar novas refeições a partir da resposta JSON
    json_response["meals"].each do |meal_data|
      meal = food_plan.meals.create!(
        name: meal_data["name"],
        time: meal_data["time"],
        objective: meal_data["objective"] || default_objective_for_meal(meal_data["name"]),
        meal_type: determine_meal_type(meal_data["name"])
      )
      
      # Adicionar alimentos à refeição
      if meal_data["foods"].is_a?(Array)
        meal_data["foods"].each do |food_data|
          meal.food_items.create!(
            name: food_data["name"],
            quantity: food_data["quantity"],
            unit: food_data["unit"]
          )
        end
      end
    end
  end
  
  def process_text_response(response, food_plan)
    Rails.logger.info("Processando resposta em texto da API da OpenAI")
    
    # Limpar refeições existentes
    food_plan.meals.destroy_all
    
    # Dividir a resposta em seções de refeições
    current_meal = nil
    meal_sections = []
    current_section = []
    
    # Padrões para identificar seções de refeições
    meal_patterns = [
      /Café\s+da\s+Manhã/i,
      /Lanche\s+da\s+Manhã/i,
      /Almoço/i,
      /Lanche\s+da\s+Tarde/i,
      /Jantar/i,
      /Ceia/i
    ]
    
    # Processar linha por linha
    response.split("\n").each do |line|
      line = line.strip
      next if line.empty?
      
      # Verificar se é o início de uma nova refeição
      if meal_patterns.any? { |pattern| line =~ pattern } || line =~ /^\d+\.\s+(.+)$/
        # Salvar a seção anterior se existir
        if current_section.any?
          meal_sections << current_section
          current_section = []
        end
      end
      
      current_section << line
    end
    
    # Adicionar a última seção se existir
    meal_sections << current_section if current_section.any?
    
    # Processar cada seção de refeição
    meal_sections.each do |section|
      process_meal_section(section, food_plan)
    end
    
    # Se nenhuma refeição foi criada, usar o método de fallback
    create_meals(food_plan) if food_plan.meals.empty?
  end
  
  def process_meal_section(section, food_plan)
    return if section.empty?
    
    # Extrair informações da refeição
    meal_name = nil
    meal_time = nil
    meal_objective = nil
    foods = []
    
    # Processar o cabeçalho da refeição
    header = section.first
    if header =~ /(.+?)(?:\s*[-–]\s*|\s+\(|\:)(.+)/
      meal_name = $1.strip
      extra_info = $2.strip
      
      # Tentar extrair o horário
      if extra_info =~ /(\d{1,2}[:.]\d{2})/
        meal_time = $1.gsub('.', ':')
      end
    else
      meal_name = header
    end
    
    # Processar o restante das linhas
    in_foods_section = false
    
    section[1..-1].each do |line|
      # Verificar se é o objetivo da refeição
      if !in_foods_section && !line.include?(':') && meal_objective.nil?
        meal_objective = line
        next
      end
      
      # Verificar se estamos na seção de alimentos
      if line =~ /alimentos|itens|ingredientes/i
        in_foods_section = true
        next
      end
      
      # Processar linha de alimento
      if in_foods_section || line =~ /[-•*]\s+(.+)/ || line =~ /^\d+\.\s+(.+)$/
        food_line = line.sub(/[-•*]\s+/, '').sub(/^\d+\.\s+/, '')
        
        # Tentar extrair quantidade e unidade
        if food_line =~ /(.+?)(?:\s*[-–:]\s*|\s+)(\d+[\.,]?\d*)\s+([a-zçãõáéíóúâêîôû]+\.?(?:\s+[a-zçãõáéíóúâêîôû]+)*)/i
          food_name = $1.strip
          quantity = $2.strip.gsub(',', '.')
          unit = $3.strip
          
          foods << { name: food_name, quantity: quantity, unit: unit }
        elsif food_line =~ /(.+?)(?:\s*[-–:]\s*|\s+)(\d+[\.,]?\d*)\s+(.+)/i
          food_name = $1.strip
          quantity = $2.strip.gsub(',', '.')
          unit = $3.strip
          
          foods << { name: food_name, quantity: quantity, unit: unit }
        else
          # Se não conseguir extrair, usar valores padrão
          foods << { name: food_line, quantity: "1", unit: "porção" }
        end
      end
    end
    
    # Criar a refeição se tiver nome
    if meal_name.present?
      begin
        meal = food_plan.meals.create!(
          name: meal_name,
          time: meal_time || default_time_for_meal(meal_name),
          objective: meal_objective || default_objective_for_meal(meal_name),
          meal_type: determine_meal_type(meal_name)
        )
        
        # Adicionar alimentos à refeição
        foods.each do |food|
          meal.food_items.create!(
            name: food[:name],
            quantity: food[:quantity],
            unit: food[:unit]
          )
        end
      rescue => e
        Rails.logger.error("Erro ao criar refeição #{meal_name}: #{e.message}")
      end
    end
  end
  
  def determine_meal_type(meal_name)
    meal_name = meal_name.downcase
    
    if meal_name.include?('café') || meal_name.include?('manhã') && meal_name.include?('café')
      'breakfast'
    elsif meal_name.include?('lanche') && (meal_name.include?('manhã') || meal_name.include?('matinal'))
      'morning_snack'
    elsif meal_name.include?('almoço')
      'lunch'
    elsif meal_name.include?('lanche') && meal_name.include?('tarde')
      'afternoon_snack'
    elsif meal_name.include?('jantar')
      'dinner'
    elsif meal_name.include?('ceia') || meal_name.include?('noite')
      'evening_snack'
    else
      # Tentar determinar pelo nome genérico
      if meal_name.include?('1') || meal_name.include?('primeira')
        'breakfast'
      elsif meal_name.include?('2') || meal_name.include?('segunda')
        'morning_snack'
      elsif meal_name.include?('3') || meal_name.include?('terceira')
        'lunch'
      elsif meal_name.include?('4') || meal_name.include?('quarta')
        'afternoon_snack'
      elsif meal_name.include?('5') || meal_name.include?('quinta')
        'dinner'
      elsif meal_name.include?('6') || meal_name.include?('sexta')
        'evening_snack'
      else
        'breakfast' # Padrão
      end
    end
  end
  
  def default_time_for_meal(meal_name)
    meal_name = meal_name.downcase
    
    if meal_name.include?('café') || meal_name.include?('manhã') && meal_name.include?('café')
      '07:00'
    elsif meal_name.include?('lanche') && (meal_name.include?('manhã') || meal_name.include?('matinal'))
      '10:00'
    elsif meal_name.include?('almoço')
      '13:00'
    elsif meal_name.include?('lanche') && meal_name.include?('tarde')
      '16:00'
    elsif meal_name.include?('jantar')
      '19:00'
    elsif meal_name.include?('ceia') || meal_name.include?('noite')
      '21:00'
    else
      '12:00' # Horário padrão
    end
  end
  
  def default_objective_for_meal(meal_name)
    meal_name = meal_name.downcase
    
    if meal_name.include?('café') || meal_name.include?('manhã') && meal_name.include?('café')
      'Fornecer energia para o início do dia'
    elsif meal_name.include?('lanche') && (meal_name.include?('manhã') || meal_name.include?('matinal'))
      'Manter o metabolismo ativo'
    elsif meal_name.include?('almoço')
      'Fornecer nutrientes essenciais'
    elsif meal_name.include?('lanche') && meal_name.include?('tarde')
      'Evitar queda de energia'
    elsif meal_name.include?('jantar')
      'Recuperação muscular e saciedade'
    elsif meal_name.include?('ceia') || meal_name.include?('noite')
      'Promover boa qualidade do sono'
    else
      'Fornecer nutrientes adequados'
    end
  end
  
  def create_food_plan
    # Verificar se já existe um plano alimentar para esta anamnese
    existing_plan = @anamnesis.food_plans.first
    
    # Gerar avaliação técnica baseada na anamnese
    technical_assessment = generate_technical_assessment
    
    # Criar descrição do plano alimentar com a avaliação técnica
    description = "#{technical_assessment}\n\nPlano alimentar gerado em #{Date.current.strftime('%d/%m/%Y')} com base na anamnese nutricional."
    
    if existing_plan
      # Se já existe, atualizar os dados
      existing_plan.update(
        name: "Plano Nutricional - #{Date.current.strftime('%d/%m/%Y')}",
        description: description,
        calories: @anamnesis.calculate_daily_calories,
        start_date: Date.current,
        end_date: Date.current + 30.days,
        created_at: Time.current,
        updated_at: Time.current
      )
      existing_plan
    else
      # Se não existe, criar um novo
      food_plan = @anamnesis.food_plans.new(
        user_id: @anamnesis.user_id,
        name: "Plano Nutricional - #{Date.current.strftime('%d/%m/%Y')}",
        description: description,
        calories: @anamnesis.calculate_daily_calories,
        start_date: Date.current,
        end_date: Date.current + 30.days
      )
      
      # Garantir que o food_plan seja salvo antes de retornar
      unless food_plan.save
        Rails.logger.error("Erro ao salvar o plano alimentar: #{food_plan.errors.full_messages.join(', ')}")
        raise "Erro ao salvar o plano alimentar: #{food_plan.errors.full_messages.join(', ')}"
      end
      
      food_plan
    end
  end
  
  def generate_technical_assessment
    # Extrair dados relevantes da anamnese
    health_data = @anamnesis.health_data || {}
    dietary_preferences = @anamnesis.dietary_preferences || {}
    restrictions = @anamnesis.restrictions || {}
    lifestyle = @anamnesis.lifestyle || {}
    goals = @anamnesis.goals || {}
    
    # Calcular IMC e classificação
    bmi = @anamnesis.bmi
    bmi_classification = if bmi
      case bmi
      when 0..18.4
        "abaixo do peso"
      when 18.5..24.9
        "peso normal"
      when 25.0..29.9
        "sobrepeso"
      when 30.0..34.9
        "obesidade grau I"
      when 35.0..39.9
        "obesidade grau II"
      else
        "obesidade grau III"
      end
    else
      "não calculado"
    end
    
    # Calcular necessidades calóricas
    calories = @anamnesis.calculate_daily_calories
    
    # Gerar avaliação técnica
    assessment = []
    
    # Dados básicos
    assessment << "AVALIAÇÃO NUTRICIONAL"
    assessment << "--------------------"
    assessment << ""
    
    # Perfil do paciente
    assessment << "Perfil: #{health_data['gender'] == 'male' ? 'Homem' : 'Mulher'} de #{@anamnesis.age} anos, #{health_data['height']} cm, #{health_data['weight']} kg."
    assessment << "IMC: #{bmi} kg/m² - Classificação: #{bmi_classification.capitalize}."
    
    # Condições de saúde
    if health_data['medical_conditions'].present? || health_data['medications'].present?
      assessment << ""
      assessment << "Considerações de Saúde:"
      assessment << "- Condições médicas: #{health_data['medical_conditions'] || 'Nenhuma informada'}"
      assessment << "- Medicamentos em uso: #{health_data['medications'] || 'Nenhum informado'}"
    end
    
    # Alergias e restrições
    allergies = [
      health_data['allergies'],
      restrictions['food_allergies'],
      restrictions['intolerances']
    ].compact.reject(&:blank?).join(", ")
    
    if allergies.present?
      assessment << ""
      assessment << "Alergias e Intolerâncias:"
      assessment << "- #{allergies}"
    end
    
    # Preferências alimentares
    if dietary_preferences.present?
      assessment << ""
      assessment << "Preferências Alimentares:"
      assessment << "- Alimentos favoritos: #{dietary_preferences['favorite_foods'] || 'Não informados'}"
      assessment << "- Alimentos não preferidos: #{dietary_preferences['disliked_foods'] || 'Não informados'}"
      assessment << "- Tipo de dieta: #{dietary_preferences['diet_type'] || 'Tradicional'}"
    end
    
    # Estilo de vida
    if lifestyle.present?
      assessment << ""
      assessment << "Estilo de Vida:"
      assessment << "- Nível de atividade física: #{lifestyle['activity_level'] || 'Não informado'}"
      assessment << "- Frequência de exercícios: #{lifestyle['exercise_frequency'] || 'Não informada'}"
      assessment << "- Ocupação: #{lifestyle['occupation'] || 'Não informada'}"
    end
    
    # Objetivos
    if goals.present?
      assessment << ""
      assessment << "Objetivos:"
      assessment << "- Objetivo de peso: #{goals['weight_goal'] || 'Manutenção'}"
      assessment << "- Objetivos de saúde: #{goals['health_objectives'] || 'Melhora geral da saúde'}"
      
      if goals['target_date'].present?
        target_date = Date.parse(goals['target_date']) rescue nil
        if target_date
          days_until = (target_date - Date.current).to_i
          assessment << "- Data alvo: #{target_date.strftime('%d/%m/%Y')} (#{days_until} dias restantes)"
        end
      end
      
      if goals['specific_needs'].present?
        assessment << "- Necessidades específicas: #{goals['specific_needs']}"
      end
    end
    
    # Necessidades nutricionais
    assessment << ""
    assessment << "Necessidades Nutricionais:"
    assessment << "- Necessidade calórica diária estimada: #{calories || 'Não calculada'} kcal"
    
    macros = @anamnesis.calculate_macros(calories)
    if macros
      assessment << "- Distribuição recomendada de macronutrientes:"
      assessment << "  * Proteínas: #{macros[:protein]}g (#{macros[:protein_percentage]}%)"
      assessment << "  * Gorduras: #{macros[:fat]}g (#{macros[:fat_percentage]}%)"
      assessment << "  * Carboidratos: #{macros[:carbs]}g (#{macros[:carb_percentage]}%)"
    end
    
    # Recomendações gerais
    assessment << ""
    assessment << "Recomendações Gerais:"
    
    # Recomendações baseadas no IMC
    if bmi
      if bmi < 18.5
        assessment << "- Foco em ganho de peso saudável com aumento gradual da ingestão calórica"
        assessment << "- Priorizar alimentos nutricionalmente densos"
      elsif bmi >= 25
        assessment << "- Foco em perda de peso gradual e sustentável"
        assessment << "- Déficit calórico moderado para preservar massa muscular"
      else
        assessment << "- Manutenção do peso atual com foco em qualidade nutricional"
      end
    end
    
    # Recomendações baseadas em condições de saúde
    if health_data['medical_conditions'].present?
      if health_data['medical_conditions'].downcase.include?('diabetes')
        assessment << "- Controle de carboidratos e índice glicêmico das refeições"
        assessment << "- Distribuição equilibrada de carboidratos ao longo do dia"
      end
      
      if health_data['medical_conditions'].downcase.include?('hipertensão')
        assessment << "- Redução do consumo de sódio"
        assessment << "- Priorizar alimentos ricos em potássio, magnésio e cálcio"
      end
      
      if health_data['medical_conditions'].downcase.include?('colesterol')
        assessment << "- Controle de gorduras saturadas e trans"
        assessment << "- Aumento da ingestão de fibras solúveis e ômega-3"
      end
    end
    
    # Recomendações gerais de hidratação
    assessment << "- Consumo adequado de água: aproximadamente 35ml por kg de peso corporal"
    
    # Recomendações baseadas no estilo de vida
    if lifestyle['activity_level'].present? && lifestyle['activity_level'].downcase.include?('ativo')
      assessment << "- Atenção à reposição de eletrólitos após atividades físicas intensas"
      assessment << "- Consumo adequado de proteínas para recuperação muscular"
    end
    
    # Juntar tudo em um texto
    assessment.join("\n")
  end
  
  def adjust_calories_by_goal(calories)
    return calories unless @anamnesis.goals && @anamnesis.goals['weight_goal']
    
    case @anamnesis.goals['weight_goal']
    when 'lose_weight', 'lose'
      (calories * 0.85).round # Déficit calórico de 15%
    when 'gain_weight', 'gain'
      (calories * 1.15).round # Superávit calórico de 15%
    else
      calories # Manter peso
    end
  end

  def generate_plan_description
    goal_text = if @anamnesis.goals && @anamnesis.goals['weight_goal']
                  case @anamnesis.goals['weight_goal']
                  when 'lose_weight', 'lose'
                    "perda de peso"
                  when 'gain_weight', 'gain'
                    "ganho de massa muscular"
                  else
                    "manutenção do peso"
                  end
                else
                  "manutenção da saúde"
                end
    
    diet_type = if @anamnesis.dietary_preferences && @anamnesis.dietary_preferences['diet_type']
                  @anamnesis.dietary_preferences['diet_type']
                else
                  "tradicional"
                end
    
    "Plano nutricional personalizado com foco em #{goal_text}, " \
    "baseado em uma dieta #{diet_type} e adaptado às suas preferências alimentares. " \
    "Este plano foi criado considerando seu perfil de saúde, estilo de vida e objetivos pessoais."
  end

  def create_meals(food_plan)
    # Determinar número de refeições com base nas preferências
    meal_frequency = if @anamnesis.dietary_preferences && @anamnesis.dietary_preferences['meal_frequency']
                       @anamnesis.dietary_preferences['meal_frequency'].to_i
                     else
                       5 # Padrão: 5 refeições
                     end
    
    meal_frequency = 5 if meal_frequency < 3 || meal_frequency > 7
    
    # Criar refeições padrão
    if meal_frequency >= 3
      create_breakfast(food_plan)
      create_lunch(food_plan)
      create_dinner(food_plan)
    end
    
    # Adicionar lanches conforme necessário
    if meal_frequency >= 4
      create_morning_snack(food_plan)
    end
    
    if meal_frequency >= 5
      create_afternoon_snack(food_plan)
    end
    
    if meal_frequency >= 6
      create_evening_snack(food_plan)
    end
  end

  def create_breakfast(food_plan)
    meal = food_plan.meals.create(
      name: "Café da Manhã",
      time: "07:00",
      meal_type: "breakfast",
      objective: "Fornecer energia para o início do dia"
    )
    
    # Adicionar alimentos com base nas preferências e restrições
    add_breakfast_foods(meal)
  end

  def add_breakfast_foods(meal)
    # Verificar se há restrições
    has_gluten_restriction = has_restriction?('glúten')
    has_lactose_restriction = has_restriction?('lactose')
    
    # Adicionar proteína
    if has_lactose_restriction
      meal.food_items.create(name: "Ovos mexidos", quantity: "2", unit: "unidades")
    else
      meal.food_items.create(name: "Iogurte natural", quantity: "1", unit: "pote pequeno")
    end
    
    # Adicionar carboidrato
    if has_gluten_restriction
      meal.food_items.create(name: "Aveia sem glúten", quantity: "3", unit: "colheres de sopa")
    else
      meal.food_items.create(name: "Pão integral", quantity: "2", unit: "fatias")
    end
    
    # Adicionar fruta
    meal.food_items.create(name: "Banana", quantity: "1", unit: "unidade")
    
    # Adicionar gordura boa
    meal.food_items.create(name: "Abacate", quantity: "1/4", unit: "unidade")
    
    # Adicionar bebida
    if has_lactose_restriction
      meal.food_items.create(name: "Chá verde", quantity: "1", unit: "xícara")
    else
      meal.food_items.create(name: "Café com leite", quantity: "1", unit: "xícara")
    end
  end

  def create_morning_snack(food_plan)
    meal = food_plan.meals.create(
      name: "Lanche da Manhã",
      time: "10:00",
      meal_type: "morning_snack",
      objective: "Manter o metabolismo ativo e evitar queda de energia"
    )
    
    # Adicionar alimentos simples
    meal.food_items.create(name: "Maçã", quantity: "1", unit: "unidade")
    meal.food_items.create(name: "Castanhas", quantity: "1", unit: "punhado pequeno")
  end

  def create_lunch(food_plan)
    meal = food_plan.meals.create(
      name: "Almoço",
      time: "13:00",
      meal_type: "lunch",
      objective: "Fornecer nutrientes essenciais para as atividades do dia"
    )
    
    # Adicionar alimentos principais
    add_main_meal_foods(meal)
  end

  def create_afternoon_snack(food_plan)
    meal = food_plan.meals.create(
      name: "Lanche da Tarde",
      time: "16:00",
      meal_type: "afternoon_snack",
      objective: "Manter a energia e evitar excessos no jantar"
    )
    
    # Verificar se há restrições
    has_gluten_restriction = has_restriction?('glúten')
    has_lactose_restriction = has_restriction?('lactose')
    
    # Adicionar proteína
    if has_lactose_restriction
      meal.food_items.create(name: "Pasta de amendoim", quantity: "1", unit: "colher de sopa")
    else
      meal.food_items.create(name: "Queijo branco", quantity: "1", unit: "fatia média")
    end
    
    # Adicionar carboidrato
    if has_gluten_restriction
      meal.food_items.create(name: "Biscoito de arroz", quantity: "4", unit: "unidades")
    else
      meal.food_items.create(name: "Torrada integral", quantity: "2", unit: "unidades")
    end
    
    # Adicionar fruta
    meal.food_items.create(name: "Pera", quantity: "1", unit: "unidade")
  end

  def create_dinner(food_plan)
    meal = food_plan.meals.create(
      name: "Jantar",
      time: "19:00",
      meal_type: "dinner",
      objective: "Fornecer nutrientes para recuperação e preparação para o descanso"
    )
    
    # Adicionar alimentos principais (versão mais leve que o almoço)
    add_main_meal_foods(meal, lighter: true)
  end

  def create_evening_snack(food_plan)
    meal = food_plan.meals.create(
      name: "Ceia",
      time: "21:30",
      meal_type: "evening_snack",
      objective: "Evitar fome durante a noite e auxiliar no sono"
    )
    
    # Verificar se há restrições
    has_lactose_restriction = has_restriction?('lactose')
    
    # Adicionar proteína leve
    if has_lactose_restriction
      meal.food_items.create(name: "Chá de camomila", quantity: "1", unit: "xícara")
      meal.food_items.create(name: "Castanhas", quantity: "1", unit: "punhado pequeno")
    else
      meal.food_items.create(name: "Iogurte natural", quantity: "1", unit: "pote pequeno")
      meal.food_items.create(name: "Mel", quantity: "1", unit: "colher de chá")
    end
    
    # Adicionar carboidrato leve
    meal.food_items.create(name: "Banana", quantity: "1/2", unit: "unidade")
  end

  def add_main_meal_foods(meal, lighter: false)
    is_vegetarian = vegetarian_diet?
    is_vegan = vegan_diet?
    
    # Adicionar proteína
    if is_vegan
      meal.food_items.create(name: "Tofu/Tempeh", quantity: lighter ? "80" : "100", unit: "g")
      meal.food_items.create(name: "Lentilhas", quantity: lighter ? "2" : "3", unit: "colheres de sopa")
    elsif is_vegetarian
      meal.food_items.create(name: "Ovos", quantity: lighter ? "1" : "2", unit: "unidades")
      meal.food_items.create(name: "Queijo", quantity: "30", unit: "g")
    else
      protein_source = preferred_protein_source
      meal.food_items.create(name: protein_source, quantity: lighter ? "100" : "150", unit: "g")
    end
    
    # Adicionar carboidratos
    carb_source = preferred_carb_source
    meal.food_items.create(name: carb_source, quantity: lighter ? "3" : "4", unit: "colheres de sopa")
    
    # Adicionar vegetais
    meal.food_items.create(name: "Salada verde variada", quantity: "1", unit: "prato")
    meal.food_items.create(name: "Legumes cozidos", quantity: "1/2", unit: "prato")
    
    # Adicionar gordura boa
    meal.food_items.create(name: "Azeite de oliva", quantity: "1", unit: "colher de sobremesa")
  end

  def create_water_plan(food_plan)
    # Calcular quantidade de água com base no peso
    weight = @anamnesis.health_data['weight'].to_f rescue 70
    daily_water_ml = (weight * 35).round # 35ml por kg de peso corporal
    
    # Ajustar com base no nível de atividade
    if @anamnesis.lifestyle && @anamnesis.lifestyle['activity_level']
      case @anamnesis.lifestyle['activity_level']
      when 'very_active', 'extra_active'
        daily_water_ml = (daily_water_ml * 1.2).round # +20% para pessoas muito ativas
      end
    end
    
    # Criar plano de hidratação
    food_plan.create_water_plan(
      daily_amount: daily_water_ml.to_s,
      recommendation: generate_water_recommendation(daily_water_ml)
    )
  end

  def generate_water_recommendation(daily_water_ml)
    glasses = (daily_water_ml / 250).round # Considerando um copo de 250ml
    
    "Beber aproximadamente #{glasses} copos de água por dia, distribuídos ao longo do dia. " \
    "Aumentar a ingestão em dias quentes ou durante atividades físicas. " \
    "Dica: tenha sempre uma garrafa de água com você."
  end

  def has_restriction?(item)
    return false unless @anamnesis.restrictions
    
    allergies = @anamnesis.restrictions['food_allergies'].to_s.downcase
    intolerances = @anamnesis.restrictions['intolerances'].to_s.downcase
    medical = @anamnesis.restrictions['medical_restrictions'].to_s.downcase
    
    [allergies, intolerances, medical].any? { |r| r.include?(item.downcase) }
  end

  def vegetarian_diet?
    return false unless @anamnesis.dietary_preferences && @anamnesis.dietary_preferences['diet_type']
    
    ['vegetarian', 'vegan'].include?(@anamnesis.dietary_preferences['diet_type'].to_s.downcase)
  end

  def vegan_diet?
    return false unless @anamnesis.dietary_preferences && @anamnesis.dietary_preferences['diet_type']
    
    @anamnesis.dietary_preferences['diet_type'].to_s.downcase == 'vegan'
  end

  def preferred_protein_source
    if @anamnesis.dietary_preferences && @anamnesis.dietary_preferences['favorite_foods']
      favorites = @anamnesis.dietary_preferences['favorite_foods'].to_s.downcase
      
      if favorites.include?('peixe')
        return "Peixe"
      elsif favorites.include?('frango') || favorites.include?('galinha')
        return "Frango"
      elsif favorites.include?('carne')
        return "Carne vermelha magra"
      end
    end
    
    # Padrão
    "Frango"
  end

  def preferred_carb_source
    if has_restriction?('glúten')
      return "Arroz integral"
    end
    
    if @anamnesis.dietary_preferences && @anamnesis.dietary_preferences['favorite_foods']
      favorites = @anamnesis.dietary_preferences['favorite_foods'].to_s.downcase
      
      if favorites.include?('batata')
        return "Batata doce"
      elsif favorites.include?('arroz')
        return "Arroz integral"
      elsif favorites.include?('quinoa')
        return "Quinoa"
      end
    end
    
    # Padrão
    "Arroz integral"
  end
end
