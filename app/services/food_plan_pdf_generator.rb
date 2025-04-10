class FoodPlanPdfGenerator
  require "prawn"
  require "prawn/table"
  require "prawn/measurement_extensions"
  require 'rqrcode'

  def initialize(food_plan)
    @food_plan = food_plan
    @anamnesis = food_plan.anamnesis
    @user = food_plan.anamnesis.user
    @profile = @user.profile
    @macros = @anamnesis.calculate_macros(@food_plan.calories)
    
    # Garantir que os campos JSON existam
    @anamnesis.health_data ||= {}
    @anamnesis.dietary_preferences ||= {}
    @anamnesis.restrictions ||= {}
    @anamnesis.lifestyle ||= {}
    @anamnesis.goals ||= {}
    
    # Cores - Esquema de cores profissional
    @primary_color = "2C7D54"    # Verde principal
    @secondary_color = "37B76A"  # Verde secundário
    @accent_color = "F9A826"     # Laranja/amarelo para destaque
    @title_color = "333333"      # Texto escuro para títulos
    @light_bg = "F8F9FA"         # Fundo claro
    @dark_text = "333333"        # Texto escuro
    @light_text = "666666"       # Texto cinza claro
    @border_color = "EAEAEA"     # Cor de borda
    @highlight_bg = "F5F9F7"     # Fundo de destaque
    @water_color = "0277BD"      # Azul para hidratação
    
    # Fontes
    @header_font = "Helvetica"
    @body_font = "Helvetica"
  end

  def generate
    pdf = Prawn::Document.new(
      page_size: "A4",
      margin: [30, 30, 30, 30],
      info: {
        Title: "Plano Alimentar - #{@anamnesis&.client_name || @user&.name || 'Cliente'}",
        Author: "NutriPlan",
        Creator: "NutriPlan",
        Producer: "Prawn",
        CreationDate: Time.now
      }
    )
    
    # Configurações de fonte padrão
    pdf.font_families.update(
      "Helvetica" => {
        normal: "Helvetica",
        italic: "Helvetica-Oblique",
        bold: "Helvetica-Bold",
        bold_italic: "Helvetica-BoldOblique"
      }
    )
    
    # Configuração padrão
    pdf.font @body_font
    pdf.font_size 11
    pdf.default_leading 5
    
    begin
      # Gerar conteúdo do PDF
      generate_cover_page(pdf)
      generate_technical_assessment(pdf)
      generate_meal_plan(pdf)
      generate_water_plan(pdf) if @food_plan.water_plan.present?
      generate_observations(pdf) if @food_plan.description.present?
      generate_footer(pdf)
    rescue => e
      # Registrar o erro
      Rails.logger.error("Erro ao gerar PDF: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      # Adicionar uma página de erro ao PDF
      pdf.start_new_page
      pdf.fill_color "FF0000"
      pdf.font(@header_font, style: :bold, size: 20) do
        pdf.text "Erro ao gerar o relatório", align: :center
      end
      
      pdf.move_down 20
      pdf.fill_color "000000"
      pdf.font(@body_font, size: 12) do
        pdf.text "Ocorreu um erro ao gerar o relatório completo. Por favor, tente novamente mais tarde ou entre em contato com o suporte."
        pdf.move_down 10
        pdf.text "Erro: #{e.message}", align: :center if Rails.env.development?
      end
    end
    
    Rails.logger.info("Total de páginas: #{pdf.page_count}")
    
    # Adicionar rodapé em todas as páginas, exceto a primeira
    add_page_footer_with_qrcode_and_numbering(pdf, "https://nutriplanbrasil.com.br")
    
    pdf
  end

  private

  def generate_cover_page(pdf)
    # Configuração da página de capa com fundo branco
    pdf.canvas do
      pdf.fill_color "FFFFFF"
      pdf.fill_rectangle [0, pdf.bounds.height], pdf.bounds.width, pdf.bounds.height
    end
    
    # Conteúdo centralizado
    content_height = 900 # Altura estimada do conteúdo
    start_y = 600
    
    # Logo e título
    pdf.bounding_box([0, start_y], width: pdf.bounds.width, height: content_height) do
      # Logo NutriPlan
      pdf.move_down 50
      pdf.font(@header_font, style: :bold, size: 26) do
        pdf.formatted_text_box [
          { text: "Nutri", color: @primary_color },
          { text: "Plan", color: @accent_color }
        ], at: [0, pdf.cursor], width: pdf.bounds.width, align: :center
      end
      
      pdf.move_down 80
      
      # Título do documento
      pdf.fill_color @title_color
      pdf.font(@header_font, style: :normal, size: 26) do
        pdf.text "PLANO ALIMENTAR PERSONALIZADO", align: :center, character_spacing: 1
      end
      
      pdf.move_down 40
      
      # Nome do cliente
      pdf.fill_color @primary_color
      pdf.font(@header_font, style: :normal, size: 24) do
        pdf.text @anamnesis.client_name || @profile&.name || "Cliente", align: :center
      end
      
      # Data
      pdf.fill_color @light_text
      pdf.font(@body_font, size: 14) do
        pdf.text "Iniciado em: #{I18n.l(Date.today, format: :long)}", align: :center
      end
    end
    
    # Rodapé da capa - Ajustado para ficar mais próximo da base da página
    pdf.bounding_box([0, 30.mm], width: pdf.bounds.width, height: 40.mm) do
      pdf.fill_color @light_text
      pdf.font(@body_font, size: 11) do
        # Linha separadora mais sutil
        pdf.stroke_color @border_color
        pdf.line_width = 0.25
        pdf.stroke_horizontal_line 50, pdf.bounds.width - 50, at: pdf.cursor
        
        pdf.move_down 15
        
        # Texto do rodapé
        pdf.text "Este plano alimentar foi desenvolvido exclusivamente para #{@anamnesis.client_name || @profile&.name || 'Cliente'} baseado em suas\nnecessidades nutricionais, preferências alimentares e objetivos específicos.", 
                 align: :center,
                 leading: 5
        
        pdf.move_down 8
        pdf.text "© #{Date.today.year} NutriPlan - Todos os direitos reservados", 
                 align: :center
      end
    end
    
    # Adicionar uma nova página após a capa
    pdf.start_new_page
  end

  def generate_technical_assessment(pdf)
    # Título da seção
    section_title(pdf, "Avaliação Técnica Nutricional")
    
    # Seção: Dados Antropométricos
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Dados Antropométricos"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    # Preparar dados com tratamento de valores nulos
    height = @anamnesis.health_data['height'].present? ? "#{@anamnesis.health_data['height']} cm" : "Não informado"
    weight = @anamnesis.health_data['weight'].present? ? "#{@anamnesis.health_data['weight']} kg" : "Não informado"
    
    # Calcular IMC apenas se altura e peso estiverem disponíveis
    bmi_info = if calculate_bmi
                "#{calculate_bmi.round(1)} (#{bmi_classification})"
              else
                "Não disponível"
              end
    
    # Criar tabela de dados antropométricos com estilo mais profissional
    data = [
      ["Idade:", calculate_age(@anamnesis.health_data['date_of_birth']) || "Não informado"],
      ["Gênero:", translate_gender(@anamnesis.health_data['gender'])],
      ["Altura:", height],
      ["Peso:", weight],
      ["IMC:", bmi_info]
    ]
    
    # Adicionar percentual de gordura se disponível
    if @anamnesis.health_data['body_fat_percentage'].present?
      data << ["Percentual de gordura:", "#{@anamnesis.health_data['body_fat_percentage']}%"]
    end
    
    # Criar tabela com estilo mais profissional
    pdf.table(data, width: pdf.bounds.width) do |t|
      t.cells.borders = []
      t.cells.padding = [8, 5, 8, 5]
      t.column(0).font_style = :bold
      t.column(0).width = 200
      t.column(0).text_color = @dark_text
      t.column(1).text_color = @dark_text
      
      # Linhas alternadas com cores diferentes
      data.each_with_index do |row_data, i|
        if i.even?
          t.row(i).background_color = @light_bg
        end
      end
    end
    
    pdf.move_down 25
    
    # Seção: Análise Metabólica
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Análise Metabólica"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    # Criar tabela de análise metabólica
    metabolic_data = []
    
    # Taxa metabólica basal
    if @anamnesis.health_data['bmr'].present?
      metabolic_data << ["Taxa metabólica basal:", "#{@anamnesis.health_data['bmr']} kcal/dia"]
    end
    
    # Gasto energético total
    if @anamnesis.health_data['tdee'].present?
      metabolic_data << ["Gasto energético total:", "#{@anamnesis.health_data['tdee']} kcal/dia"]
    end
    
    # Meta calórica
    metabolic_data << ["Meta calórica diária:", "#{@food_plan.calories} kcal/dia"]
    
    # Criar tabela com estilo mais profissional
    pdf.table(metabolic_data, width: pdf.bounds.width) do |t|
      t.cells.borders = []
      t.cells.padding = [8, 5, 8, 5]
      t.column(0).font_style = :bold
      t.column(0).width = 200
      t.column(0).text_color = @dark_text
      t.column(1).text_color = @dark_text
      
      # Linhas alternadas com cores diferentes
      metabolic_data.each_with_index do |row_data, i|
        if i.even?
          t.row(i).background_color = @light_bg
        end
      end
    end
    
    pdf.move_down 25
    
    # Distribuição de Macronutrientes
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Distribuição de Macronutrientes"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    # Caixas de macronutrientes
    box_width = (pdf.bounds.width - 20) / 3
    box_height = 80
    
    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: box_height) do
      # Proteínas
      pdf.bounding_box([0, box_height], width: box_width, height: box_height) do
        pdf.fill_color @light_bg
        pdf.fill_rectangle [0, box_height], box_width, box_height
        
        pdf.fill_color @primary_color
        pdf.font(@header_font, style: :bold, size: 14) do
          pdf.text_box "Proteínas", 
                      at: [0, box_height - 10], 
                      width: box_width, 
                      align: :center
        end
        
        pdf.fill_color @dark_text
        pdf.font(@body_font, style: :bold, size: 20) do
          pdf.text_box "#{@macros[:protein_percentage]}%", 
                      at: [0, box_height - 35], 
                      width: box_width, 
                      align: :center
        end
        
        pdf.font(@body_font, size: 16) do
          pdf.text_box "#{@macros[:protein_grams]}g", 
                      at: [0, box_height - 60], 
                      width: box_width, 
                      align: :center
        end
      end
      
      # Carboidratos
      pdf.bounding_box([box_width + 10, box_height], width: box_width, height: box_height) do
        pdf.fill_color @light_bg
        pdf.fill_rectangle [0, box_height], box_width, box_height
        
        pdf.fill_color @primary_color
        pdf.font(@header_font, style: :bold, size: 14) do
          pdf.text_box "Carboidratos", 
                      at: [0, box_height - 10], 
                      width: box_width, 
                      align: :center
        end
        
        pdf.fill_color @dark_text
        pdf.font(@body_font, style: :bold, size: 20) do
          pdf.text_box "#{@macros[:carb_percentage]}%", 
                      at: [0, box_height - 35], 
                      width: box_width, 
                      align: :center
        end
        
        pdf.font(@body_font, size: 16) do
          pdf.text_box "#{@macros[:carb_grams]}g", 
                      at: [0, box_height - 60], 
                      width: box_width, 
                      align: :center
        end
      end
      
      # Gorduras
      pdf.bounding_box([(box_width * 2) + 20, box_height], width: box_width, height: box_height) do
        pdf.fill_color @light_bg
        pdf.fill_rectangle [0, box_height], box_width, box_height
        
        pdf.fill_color @primary_color
        pdf.font(@header_font, style: :bold, size: 14) do
          pdf.text_box "Gorduras", 
                      at: [0, box_height - 10], 
                      width: box_width, 
                      align: :center
        end
        
        pdf.fill_color @dark_text
        pdf.font(@body_font, style: :bold, size: 20) do
          pdf.text_box "#{@macros[:fat_percentage]}%", 
                      at: [0, box_height - 35], 
                      width: box_width, 
                      align: :center
        end
        
        pdf.font(@body_font, size: 16) do
          pdf.text_box "#{@macros[:fat_grams]}g", 
                      at: [0, box_height - 60], 
                      width: box_width, 
                      align: :center
        end
      end
    end
    
    pdf.move_down box_height + 10
    
    # Verificar se há espaço suficiente para as próximas seções
    if pdf.cursor < 250
      pdf.start_new_page
      add_page_header(pdf, "Avaliação Técnica Nutricional")
    end
    
    # Estilo de Vida
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Estilo de Vida"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    # Criar tabela de estilo de vida
    lifestyle_data = [
      ["Nível de Atividade:", translate_activity_level(@anamnesis.lifestyle['activity_level'])],
      ["Frequência de Exercícios:", translate_exercise_frequency(@anamnesis.lifestyle['exercise_frequency'])],
      ["Nível de Estresse:", translate_stress_level(@anamnesis.lifestyle['stress_level'])],
      ["Horas de Sono:", translate_sleep_hours(@anamnesis.lifestyle['sleep_hours'])]
    ]
    
    if @anamnesis.lifestyle['occupation'].present?
      lifestyle_data.unshift(["Ocupação:", @anamnesis.lifestyle['occupation']])
    end
    
    # Criar tabela com estilo mais profissional
    pdf.table(lifestyle_data, width: pdf.bounds.width) do |t|
      t.cells.borders = []
      t.cells.padding = [8, 5, 8, 5]
      t.column(0).font_style = :bold
      t.column(0).width = 200
      t.column(0).text_color = @dark_text
      t.column(1).text_color = @dark_text
      
      # Linhas alternadas com cores diferentes
      lifestyle_data.each_with_index do |row_data, i|
        if i.even?
          t.row(i).background_color = @light_bg
        end
      end
    end
    
    pdf.move_down 25
    
    # Objetivos
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Objetivos"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    # Criar tabela de objetivos
    goals_data = [
      ["Objetivo de Peso:", translate_weight_goal(@anamnesis.goals['weight_goal'])]
    ]
    
    # Adicionar peso alvo se disponível
    if @anamnesis.goals['target_weight'].present?
      goals_data << ["Peso Alvo:", "#{@anamnesis.goals['target_weight']} kg"]
    end
    
    # Tratar data alvo com segurança
    if @anamnesis.goals['target_date'].present?
      begin
        target_date = @anamnesis.goals['target_date'].is_a?(String) ? 
                      Date.parse(@anamnesis.goals['target_date']) : 
                      @anamnesis.goals['target_date'].to_date
        goals_data << ["Data Alvo:", I18n.l(target_date, format: :long)]
      rescue
        goals_data << ["Data Alvo:", @anamnesis.goals['target_date'].to_s]
      end
    end
    
    if @anamnesis.goals['health_objectives'].present?
      goals_data << ["Objetivos de Saúde:", @anamnesis.goals['health_objectives']]
    end
    
    if @anamnesis.goals['specific_needs'].present?
      goals_data << ["Necessidades Específicas:", @anamnesis.goals['specific_needs']]
    end
    
    # Criar tabela com estilo mais profissional
    pdf.table(goals_data, width: pdf.bounds.width) do |t|
      t.cells.borders = []
      t.cells.padding = [8, 5, 8, 5]
      t.column(0).font_style = :bold
      t.column(0).width = 200
      t.column(0).text_color = @dark_text
      t.column(1).text_color = @dark_text
      
      # Linhas alternadas com cores diferentes
      goals_data.each_with_index do |row_data, i|
        if i.even?
          t.row(i).background_color = @light_bg
        end
      end
    end
    
    # Adicionar rodapé com QR code e numeração
    add_page_footer_with_qrcode_and_numbering(pdf, "https://nutriplanbrasil.com.br")
    
    # Iniciar nova página para o plano alimentar
    pdf.start_new_page
  end

  def generate_meal_plan(pdf)
    section_title(pdf, "Plano Alimentar Diário")
    
    # Introdução ao plano alimentar
    pdf.fill_color @dark_text
    pdf.font(@body_font, size: 12) do
      pdf.text "Este plano alimentar foi personalizado de acordo com suas necessidades nutricionais, preferências e objetivos. Siga as orientações abaixo para obter os melhores resultados."
    end
    
    pdf.move_down 20
    
    # Título da seção de refeições
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Refeições Diárias"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    @food_plan.meals.order(:time).each do |meal|
      # Verificar se há espaço suficiente para a refeição
      # Estimamos que cada refeição precise de pelo menos 150 pontos de espaço
      # mais 20 pontos para cada item alimentar
      estimated_space_needed = 150 + (meal.food_items.count * 20)
      
      if pdf.cursor < estimated_space_needed
        pdf.start_new_page
        add_page_header(pdf, "Plano Alimentar Diário")
        
        # Título da seção de refeições na nova página
        pdf.font(@header_font, style: :bold, size: 16) do
          pdf.fill_color @primary_color
          pdf.text "Refeições Diárias (continuação)"
        end
        
        pdf.stroke_color @border_color
        pdf.line_width = 1
        pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
        pdf.move_down 15
      end
      
      # Card da refeição com fundo
      pdf.fill_color @light_bg
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 40
      
      # Cabeçalho da refeição
      pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width, height: 40) do
        # Nome da refeição
        pdf.fill_color @primary_color
        pdf.font(@header_font, style: :bold, size: 16) do
          pdf.text_box meal.name, 
                      at: [15, 30], 
                      width: pdf.bounds.width / 2 - 20, 
                      height: 30, 
                      valign: :center
        end
        
        # Horário da refeição
        pdf.fill_color @light_text
        pdf.font(@body_font, size: 14) do
          pdf.text_box meal.time, 
                      at: [pdf.bounds.width / 2, 30], 
                      width: pdf.bounds.width / 2 - 15, 
                      height: 30, 
                      align: :right, 
                      valign: :center
        end
      end
      
      pdf.move_down 45
      
      # Objetivo da refeição
      if meal.objective.present?
        pdf.fill_color @dark_text
        pdf.font(@body_font, style: :italic, size: 11) do
          pdf.text "Objetivo: #{meal.objective}"
        end
        pdf.move_down 10
      end
      
      # Itens alimentares
      meal.food_items.each do |item|
        # Verificar se há espaço suficiente para o item e seus substitutos
        substitutes_count = item.has_substitutes? ? item.substitutes.count : 0
        item_space_needed = 15 + (substitutes_count * 10) + 10
        
        if pdf.cursor < item_space_needed
          pdf.start_new_page
          add_page_header(pdf, "Plano Alimentar Diário")
          
          # Título da seção de refeições na nova página
          pdf.font(@header_font, style: :bold, size: 16) do
            pdf.fill_color @primary_color
            pdf.text "#{meal.name} (continuação)"
          end
          
          pdf.stroke_color @border_color
          pdf.line_width = 1
          pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
          pdf.move_down 15
        end
        
        # Item alimentar com estilo mais profissional
        pdf.fill_color @dark_text
        pdf.font(@body_font, size: 12) do
          pdf.text_box "•", at: [0, pdf.cursor], width: 10, height: 15
          pdf.text_box item.name, at: [15, pdf.cursor], width: pdf.bounds.width - 100, height: 15
          pdf.text_box "#{item.quantity} #{item.unit}", at: [pdf.bounds.width - 80, pdf.cursor], width: 80, height: 15, align: :right
        end
        
        pdf.move_down 20
        
        # Substitutos
        if item.has_substitutes?
          pdf.indent(20) do
            pdf.fill_color @light_text
            pdf.font(@body_font, style: :italic, size: 10) do
              pdf.text "Opções de substituição:"
              
              item.substitutes.each do |substitute|
                name = substitute["name"] || substitute[:name]
                quantity = substitute["quantity"] || substitute[:quantity]
                unit = substitute["unit"] || substitute[:unit]
                
                pdf.text "- #{name} - #{quantity} #{unit}"
              end
            end
          end
          
          pdf.move_down 10
        end
      end
      
      pdf.move_down 20
    end
    
    # Adicionar rodapé com QR code e numeração
    #add_page_footer_with_qrcode_and_numbering(pdf, "https://nutriplanbrasil.com.br")
    
    # Iniciar nova página para o plano de hidratação
    pdf.start_new_page
  end

  def generate_water_plan(pdf)
    # Verificar se há espaço suficiente na página atual
    if pdf.cursor < 250
      pdf.start_new_page
    end
    
    section_title(pdf, "Plano de Hidratação")
    
    # Título da seção
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @water_color
      pdf.text "Recomendação Diária de Água"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    # Fundo azul claro para o card de hidratação
    pdf.fill_color "E1F5FE"
    pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 120
    
    # Conteúdo do plano de hidratação
    pdf.fill_color @water_color
    pdf.font(@header_font, style: :bold, size: 24) do
      pdf.text_box "#{@food_plan.water_plan.daily_amount} litros/dia", 
                  at: [0, pdf.cursor - 20], 
                  width: pdf.bounds.width, 
                  height: 30, 
                  align: :center
    end
    
    pdf.move_down 50
    
    # Recomendação de hidratação
    recommendation = @food_plan.water_plan.recommendation.present? ? 
                    @food_plan.water_plan.recommendation : 
                    "Distribua o consumo ao longo do dia. Aumente a ingestão em dias quentes ou de atividade física intensa."
    
    pdf.fill_color @water_color
    pdf.font(@body_font, size: 12) do
      pdf.text_box recommendation, 
                  at: [20, pdf.cursor], 
                  width: pdf.bounds.width - 40, 
                  height: 60, 
                  align: :center
    end
    
    pdf.move_down 80
    
    # Tabela de horários sugeridos
    pdf.move_down 20
    pdf.fill_color @dark_text
    pdf.font(@header_font, style: :bold, size: 14) do
      pdf.text "Horários Sugeridos para Hidratação"
    end
    
    pdf.move_down 10
    
    # Criar tabela de horários
    water_schedule = [
      ["Ao acordar", "1 copo (250ml)", "Ativa o metabolismo e hidrata após o período de sono"],
      ["Meio da manhã", "1 copo (250ml)", "Mantém a hidratação entre as refeições"],
      ["Antes do almoço", "1 copo (250ml)", "Prepara o sistema digestivo"],
      ["Durante o almoço", "1 copo (250ml)", "Auxilia na digestão"],
      ["Meio da tarde", "1 copo (250ml)", "Mantém a energia e foco"],
      ["Antes do jantar", "1 copo (250ml)", "Prepara o sistema digestivo"],
      ["Durante o jantar", "1 copo (250ml)", "Auxilia na digestão"],
      ["Antes de dormir", "1 copo (250ml)", "Hidrata para o período de sono"]
    ]
    
    pdf.table(water_schedule, width: pdf.bounds.width) do |t|
      t.cells.padding = [8, 10, 8, 10]
      t.column(0).font_style = :bold
      t.column(0).width = 120
      t.column(1).width = 120
      t.column(0).text_color = @water_color
      
      # Estilizar cabeçalho
      t.row(0).background_color = @light_bg
      t.row(0).text_color = @dark_text
      
      # Linhas alternadas com cores diferentes
      water_schedule.each_with_index do |row_data, i|
        if i.even? && i > 0
          t.row(i).background_color = "F5F9FF"
        end
      end
    end
    
    # Dicas de hidratação
    pdf.move_down 20
    pdf.fill_color @dark_text
    pdf.font(@header_font, style: :bold, size: 14) do
      pdf.text "Dicas para Manter-se Hidratado"
    end
    
    pdf.move_down 10
    
    tips = [
      "Tenha sempre uma garrafa de água por perto",
      "Adicione rodelas de limão, pepino ou folhas de hortelã para dar sabor à água",
      "Configure lembretes no celular para beber água regularmente",
      "Consuma alimentos ricos em água como melancia, pepino e laranja",
      "Reduza o consumo de bebidas com cafeína, que podem ter efeito diurético"
    ]
    
    pdf.fill_color @dark_text
    pdf.font(@body_font, size: 11) do
      tips.each do |tip|
        pdf.text "• #{tip}"
        pdf.move_down 5
      end
    end
    
    # Adicionar rodapé com QR code e numeração
    #add_page_footer_with_qrcode_and_numbering(pdf, "https://nutriplanbrasil.com.br")
    
    # Iniciar nova página para as observações
    pdf.start_new_page
  end

  def generate_observations(pdf)
    # Verificar se há espaço suficiente na página atual
    if pdf.cursor < 250
      pdf.start_new_page
    end
    
    section_title(pdf, "Observações e Recomendações")
    
    # Título da seção
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Orientações Gerais"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    # Fundo para as observações
    pdf.fill_color @light_bg
    pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 100
    
    # Conteúdo das observações
    pdf.fill_color @dark_text
    pdf.font(@body_font, size: 12) do
      pdf.text_box @food_plan.description, 
                  at: [10, pdf.cursor - 10], 
                  width: pdf.bounds.width - 20, 
                  height: 80
    end
    
    pdf.move_down 110
    
    # Seção de dicas e sugestões
    pdf.font(@header_font, style: :bold, size: 14) do
      pdf.fill_color @primary_color
      pdf.text "Dicas para Seguir o Plano com Sucesso"
    end
    
    pdf.move_down 10
    
    tips = [
      "Mantenha horários regulares para as refeições",
      "Beba água conforme recomendado no plano de hidratação",
      "Evite pular refeições, isso pode levar a excessos nas próximas refeições",
      "Utilize as opções de substituição quando necessário, mantendo as proporções indicadas",
      "Prepare suas refeições com antecedência para evitar escolhas impulsivas",
      "Leia os rótulos dos alimentos e prefira opções menos processadas",
      "Pratique atividade física regularmente, conforme orientação do seu profissional"
    ]
    
    pdf.fill_color @dark_text
    pdf.font(@body_font, size: 11) do
      tips.each do |tip|
        pdf.text "• #{tip}"
        pdf.move_down 5
      end
    end
    
    # Adicionar rodapé com QR code e numeração
    #add_page_footer_with_qrcode_and_numbering(pdf, "https://nutriplanbrasil.com.br")
  end

  def generate_footer(pdf)
    pdf.start_new_page
    
    section_title(pdf, "Informações Adicionais")
    
    # Título da seção
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Acompanhamento e Ajustes"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    # Informações sobre o acompanhamento
    pdf.fill_color @dark_text
    pdf.font(@body_font, size: 12) do
      pdf.text "Este plano alimentar tem duração recomendada de 30 dias, após os quais deve ser realizada uma avaliação de progresso e possíveis ajustes."
      
      pdf.move_down 10
      
      pdf.text "Registre diariamente:"
      pdf.move_down 5
      
      # Lista de itens para registrar
      items = [
        "Sensações de fome e saciedade",
        "Energia e disposição ao longo do dia",
        "Qualidade do sono",
        "Dificuldades encontradas para seguir o plano"
      ]
      
      items.each do |item|
        pdf.text "• #{item}"
      end
      
      pdf.move_down 15
      
      # Informações de contato
      pdf.text "Em caso de dúvidas ou dificuldades, entre em contato:"
      pdf.move_down 5
      pdf.text "E-mail: contato@nutriplanbrasil.com.br"
      pdf.text "Telefone: (11) 9876-5432"
    end
    
    pdf.move_down 30
    
    # Aviso legal
    pdf.font(@header_font, style: :bold, size: 16) do
      pdf.fill_color @primary_color
      pdf.text "Aviso Legal"
    end
    
    pdf.stroke_color @border_color
    pdf.line_width = 1
    pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 5
    pdf.move_down 15
    
    pdf.fill_color @dark_text
    pdf.font(@body_font, size: 10) do
      pdf.text "Este plano alimentar foi elaborado especificamente para o paciente mencionado, com base nas informações fornecidas durante a avaliação nutricional. Não deve ser seguido por outras pessoas sem orientação profissional."
      
      pdf.move_down 10
      
      pdf.text "O acompanhamento regular com um nutricionista é fundamental para o sucesso do tratamento. Este documento não substitui consultas presenciais ou orientações específicas do seu profissional de saúde."
      
      pdf.move_down 10
      
      pdf.text "© #{Date.today.year} NutriPlan - Todos os direitos reservados."
    end
    
    # Adicionar rodapé com QR code e numeração
    # add_page_footer_with_qrcode_and_numbering(pdf, "https://nutriplanbrasil.com.br")
  end
  
  # Adiciona um rodapé com QR code e numeração de página em cada página
  def add_page_footer_with_qrcode_and_numbering(pdf, url)
    # Configurar o rodapé para aparecer em todas as páginas, exceto a primeira
    pdf.repeat(:all, dynamic: true) do
      next if pdf.page_number == 1
      
      # Salvar o estado atual
      pdf.save_graphics_state
      
      # Calcular posição do rodapé (20mm da base da página)
      footer_y = 10.mm
      
      # Adicionar linha separadora acima do rodapé
      pdf.stroke_color @border_color
      pdf.line_width = 0.5
      pdf.stroke_horizontal_line 0, pdf.bounds.width, at: footer_y + 10.mm
      
      # Adicionar informações do rodapé
      pdf.font(@body_font, size: 8) do
        pdf.fill_color @light_text
        
        # Nome do paciente à esquerda
        patient_name = @profile&.name || "Cliente"
        pdf.text_box "Plano Alimentar Personalizado - #{patient_name}", 
                    at: [0, footer_y + 5.mm], 
                    width: pdf.bounds.width - 60, # Reduzir largura para evitar sobreposição
                    height: 10
        
        # Número da página à direita
        pdf.text_box "Página #{pdf.page_number} de #{pdf.page_count}", 
                    at: [pdf.bounds.width - 80, footer_y + 5.mm], 
                    width: 80,
                    height: 10,
                    align: :right
      end
      
      # Restaurar o estado
      pdf.restore_graphics_state
    end
  end
  
  # Gera um QR code para a URL fornecida
  def generate_qrcode(url)
    qrcode = RQRCode::QRCode.new(url)
    
    # Converter para PNG com configurações para melhor escaneamento
    qrcode.as_png(
      bit_depth: 1,
      border_modules: 1,
      color_mode: ChunkyPNG::COLOR_TRUECOLOR,
      color: ChunkyPNG::Color.from_hex("000000"),  # Preto puro
      file: nil,
      fill: ChunkyPNG::Color.from_hex("ffffff"),   # Branco puro
      module_px_size: 10,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 200
    ).to_s
  end
  
  # Métodos auxiliares
  
  def section_title(pdf, title)
    # Adicionar cabeçalho de página se for uma nova página
    if pdf.cursor > pdf.bounds.height - 50
      add_page_header(pdf, title)
    else
      # Título da seção
      pdf.fill_color @primary_color
      pdf.font(@header_font, style: :bold, size: 16) do
        pdf.text title
      end
      
      # Linha decorativa abaixo do título
      pdf.stroke_color @border_color
      pdf.line_width = 2
      pdf.stroke_horizontal_line 0, pdf.bounds.width, at: pdf.cursor - 8
      
      pdf.move_down 10
    end
  end
  
  # Adiciona um cabeçalho de página padronizado
  def add_page_header(pdf, title)
    # Cabeçalho com título da página e informações do cliente
    pdf.bounding_box([0, pdf.bounds.height], width: pdf.bounds.width, height: 50) do
      # Título da página
      pdf.fill_color @primary_color
      pdf.font(@header_font, style: :bold, size: 24) do
        pdf.text_box title, 
                    at: [0, 40], 
                    width: pdf.bounds.width / 2, 
                    height: 30,
                    valign: :center
      end
      
      # Informações do cliente à direita
      pdf.fill_color @light_text
      pdf.font(@body_font, size: 14) do
        pdf.text_box @profile&.name || "Cliente", 
                    at: [pdf.bounds.width / 2, 40], 
                    width: pdf.bounds.width / 2, 
                    height: 20,
                    align: :right
                    
        pdf.text_box I18n.l(Date.today, format: :long), 
                    at: [pdf.bounds.width / 2, 20], 
                    width: pdf.bounds.width / 2, 
                    height: 20,
                    align: :right
      end
      
      # Linha decorativa abaixo do cabeçalho
      pdf.stroke_color @border_color
      pdf.line_width = 1
      pdf.stroke_horizontal_line 0, pdf.bounds.width, at: 0
    end
    
    pdf.move_down 60
  end
  
  def calculate_age(birth_date)
    return nil unless birth_date
    
    begin
      birth_date = birth_date.to_date if birth_date.is_a?(String)
      
      now = Date.today
      age = now.year - birth_date.year
      
      # Ajustar se ainda não fez aniversário este ano
      age -= 1 if now < birth_date + age.years
      
      "#{age} anos"
    rescue
      "Idade não disponível"
    end
  end
  
  def calculate_bmi
    return nil unless @anamnesis.health_data['height'].present? && @anamnesis.health_data['weight'].present?
    
    begin
      height_in_meters = @anamnesis.health_data['height'].to_f / 100
      return nil if height_in_meters <= 0  # Evitar divisão por zero
      
      bmi = @anamnesis.health_data['weight'].to_f / (height_in_meters * height_in_meters)
      return nil if bmi <= 0 || bmi > 100  # Validar resultado
      
      bmi
    rescue
      nil
    end
  end
  
  def bmi_classification
    bmi = calculate_bmi
    return nil unless bmi
    
    case bmi
    when 0..16.9
      "Muito abaixo do peso"
    when 17..18.4
      "Abaixo do peso"
    when 18.5..24.9
      "Peso normal"
    when 25..29.9
      "Sobrepeso"
    when 30..34.9
      "Obesidade Grau I"
    when 35..39.9
      "Obesidade Grau II"
    else
      "Obesidade Grau III"
    end
  end
  
  def meal_color_hex(meal_type)
    case meal_type
    when "breakfast"
      "3498DB" # Azul
    when "morning_snack"
      "27AE60" # Verde
    when "lunch"
      "E74C3C" # Vermelho
    when "afternoon_snack"
      "F39C12" # Laranja
    when "dinner"
      "9B59B6" # Roxo
    when "supper"
      "34495E" # Azul escuro
    else
      @primary_color
    end
  end
  
  # Métodos de tradução
  
  def translate_gender(gender)
    return "Não informado" unless gender.present?
    
    gender_map = {
      "male" => "Masculino",
      "female" => "Feminino",
      "other" => "Outro",
      "prefer_not_to_say" => "Prefere não informar"
    }
    
    gender_map[gender] || gender
  end
  
  def translate_diet_type(diet_type)
    return "Tradicional" unless diet_type.present?
    
    diet_map = {
      "traditional" => "Tradicional (sem restrições)",
      "vegetarian" => "Vegetariano",
      "vegan" => "Vegano",
      "low_carb" => "Baixo Carboidrato",
      "keto" => "Cetogênica",
      "paleo" => "Paleolítica",
      "mediterranean" => "Mediterrânea",
      "gluten_free" => "Sem Glúten",
      "lactose_free" => "Sem Lactose"
    }
    
    diet_map[diet_type] || diet_type
  end
  
  def translate_activity_level(activity_level)
    return "Não informado" unless activity_level.present?
    
    activity_map = {
      "sedentary" => "Sedentário",
      "lightly_active" => "Levemente ativo",
      "moderately_active" => "Moderadamente ativo",
      "very_active" => "Muito ativo",
      "extremely_active" => "Extremamente ativo"
    }
    
    activity_map[activity_level] || activity_level
  end
  
  def translate_exercise_frequency(frequency)
    return "Não informado" unless frequency.present?
    
    frequency_map = {
      "never" => "Nunca",
      "1-2_per_week" => "1-2 vezes por semana",
      "3-4_per_week" => "3-4 vezes por semana",
      "5-6_per_week" => "5-6 vezes por semana",
      "daily" => "Diariamente"
    }
    
    frequency_map[frequency] || frequency
  end
  
  def translate_stress_level(stress_level)
    return "Não informado" unless stress_level.present?
    
    stress_map = {
      "low" => "Baixo",
      "moderate" => "Moderado",
      "high" => "Alto"
    }
    
    stress_map[stress_level] || stress_level
  end
  
  def translate_sleep_hours(sleep_hours)
    return "Não informado" unless sleep_hours.present?
    
    sleep_map = {
      "<5" => "Menos de 5 horas",
      "5-6" => "5-6 horas",
      "7-8" => "7-8 horas",
      ">8" => "Mais de 8 horas"
    }
    
    sleep_map[sleep_hours] || sleep_hours
  end
  
  def translate_weight_goal(weight_goal)
    return "Não informado" unless weight_goal.present?
    
    goal_map = {
      "lose_weight" => "Perda de peso",
      "maintain_weight" => "Manutenção de peso",
      "gain_weight" => "Ganho de peso",
      "gain_muscle" => "Ganho de massa muscular"
    }
    
    goal_map[weight_goal] || weight_goal
  end
end
