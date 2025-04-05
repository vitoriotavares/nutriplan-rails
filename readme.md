# Documento de Requisitos - Sistema de Planos Alimentares Personalizados

## 1. Visão Geral do Sistema

O sistema tem como objetivo criar planos alimentares personalizados baseados nas informações fornecidas pelos usuários através de um questionário de anamnese. O sistema será desenvolvido com Rails 8 para backend e frontend, utilizando PostgreSQL para armazenamento de dados, TailwindCSS 4 para estilização e Stimulus.js para interatividade no lado do cliente.

## 2. Arquitetura Técnica

### 2.1 Backend e Frontend
- **Framework**: Ruby on Rails 8 (full-stack)
- **Banco de Dados**: PostgreSQL
- **Autenticação**: Devise ou rodauth
- **Autorização**: Pundit
- **Processamento de PDFs**: Prawn ou WickedPDF
- **Armazenamento de arquivos**: Active Storage com configuração para armazenamento local ou em nuvem

### 2.2 Frontend
- **CSS Framework**: TailwindCSS 4
- **JavaScript Framework**: Stimulus.js
- **Validação de formulários**: HTML5 + Stimulus.js
- **View Components**: ViewComponent
- **Gerenciamento de eventos**: Request.js (Rails UJS) e Turbo
- **Renderização de HTML**: Hotwire (Turbo Frames e Turbo Streams)

## 3. Requisitos Funcionais

### 3.1 Gerenciamento de Usuários
- RF01: Cadastro de novos usuários
- RF02: Login de usuários
- RF03: Recuperação de senha
- RF04: Gerenciamento de perfil (editar informações pessoais)
- RF05: Histórico de planos alimentares gerados

### 3.2 Questionário de Anamnese
- RF06: Formulário em etapas (steps) com persistência entre etapas
- RF07: Validação de campos em tempo real utilizando Stimulus.js
- RF08: Navegação entre etapas sem recarregar a página inteira usando Turbo Frames
- RF09: Suporte a upload de documentos (opcional - exames, relatórios médicos) via Active Storage

### 3.3 Geração de Planos Alimentares
- RF10: Análise automática dos dados da anamnese
- RF11: Geração de plano alimentar personalizado baseado nas informações do usuário
- RF12: Cálculo de necessidades calóricas e distribuição de macronutrientes
- RF13: Sugestão de receitas compatíveis com as preferências e restrições do usuário
- RF14: Personalização das recomendações de hidratação

### 3.4 Apresentação e Distribuição do Plano
- RF15: Geração de PDF com layout profissional usando Prawn ou WickedPDF
- RF16: Envio automático do plano por e-mail usando ActionMailer
- RF17: Visualização do plano na plataforma
- RF18: Exportação do plano em diferentes formatos (PDF, imprimir)

### 3.5 Funcionalidades Adicionais
- RF19: Lista de compras baseada no plano alimentar
- RF20: Receitas detalhadas com instruções de preparo
- RF21: Dicas de adaptação do plano para situações específicas
- RF22: Possibilidade de solicitação de ajustes no plano

## 4. Requisitos Não Funcionais

### 4.1 Desempenho e Escalabilidade
- RNF01: Tempo de resposta do servidor menor que 300ms para operações principais
- RNF02: Capacidade de atender pelo menos 1000 usuários simultâneos
- RNF03: Geração de PDF em menos de 5 segundos
- RNF04: Otimização para Rails 8 com recursos como carregamento paralelo e precompilação eficiente

### 4.2 Segurança
- RNF05: Criptografia de dados sensíveis dos usuários
- RNF06: Conformidade com LGPD (Lei Geral de Proteção de Dados)
- RNF07: Implementação de HTTPS em todas as comunicações
- RNF08: Proteção contra ataques comuns (XSS, CSRF, SQL Injection)
- RNF09: Uso das novas funcionalidades de segurança do Rails 8

### 4.3 Usabilidade
- RNF10: Interface responsiva usando recursos avançados do TailwindCSS 4
- RNF11: Tempo de carregamento das páginas menor que 2 segundos utilizando Turbo
- RNF12: Compatibilidade com os principais navegadores (Chrome, Firefox, Safari, Edge)
- RNF13: Acessibilidade conforme diretrizes WCAG 2.1 AA

### 4.4 Operacionais
- RNF14: Logs detalhados para monitoramento do sistema
- RNF15: Backups diários do banco de dados
- RNF16: Uso de cache eficiente com Rails 8 para reduzir carga no servidor

## 5. Modelagem de Dados

### 5.1 Principais Entidades

#### Users
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  has_one :profile, dependent: :destroy
  has_many :anamneses, dependent: :destroy
  has_many :food_plans, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
```

#### Profiles
```ruby
# app/models/profile.rb
class Profile < ApplicationRecord
  belongs_to :user
  
  validates :height, :weight, :date_of_birth, presence: true
end
```

#### Anamnesis
```ruby
# app/models/anamnesis.rb
class Anamnesis < ApplicationRecord
  belongs_to :user
  has_one :food_plan
  
  store_accessor :health_data
  store_accessor :physical_activity
  store_accessor :food_preferences
  store_accessor :restrictions
  store_accessor :goals
  
  validates :user_id, presence: true
end
```

#### FoodPlans
```ruby
# app/models/food_plan.rb
class FoodPlan < ApplicationRecord
  belongs_to :user
  belongs_to :anamnesis
  has_many :meals, dependent: :destroy
  has_one :water_plan, dependent: :destroy
  has_one :grocery_list, dependent: :destroy
  
  store_accessor :macronutrient_distribution
  
  validates :caloric_goal, presence: true
end
```

#### Meals
```ruby
# app/models/meal.rb
class Meal < ApplicationRecord
  belongs_to :food_plan
  has_many :food_items, dependent: :destroy
  
  validates :name, :time, :objective, presence: true
  enum meal_type: [:breakfast, :morning_snack, :lunch, :afternoon_snack, :dinner, :evening_snack]
end
```

#### FoodItems
```ruby
# app/models/food_item.rb
class FoodItem < ApplicationRecord
  belongs_to :meal
  
  validates :name, :quantity, :unit, presence: true
end
```

#### WaterPlan
```ruby
# app/models/water_plan.rb
class WaterPlan < ApplicationRecord
  belongs_to :food_plan
  
  store_accessor :distribution
  
  validates :daily_recommendation, presence: true
end
```

#### GroceryList
```ruby
# app/models/grocery_list.rb
class GroceryList < ApplicationRecord
  belongs_to :food_plan
  
  store_accessor :items
end
```

#### Recipe
```ruby
# app/models/recipe.rb
class Recipe < ApplicationRecord
  has_and_belongs_to_many :food_items
  
  store_accessor :ingredients
  store_accessor :instructions
  store_accessor :nutritional_info
  
  validates :name, :preparation_time, :cooking_time, presence: true
end
```

## 6. Controladores e Rotas

### 6.1 Principais Controladores

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Autenticação
  resource :session, only: [:new, :create, :destroy]
  resources :users, only: [:new, :create]
  
  # Anamnese e planos alimentares
  resources :anamneses do
    member do
      get :step1, :step2, :step3, :step4, :step5
      post :save_step1, :save_step2, :save_step3, :save_step4, :save_step5
    end
  end
  
  resources :food_plans do
    member do
      get :download_pdf
      post :send_email
    end
    resources :meals, shallow: true
    resource :water_plan
    resource :grocery_list
  end
  
  resources :recipes
  
  root to: 'home#index'
end
```

### 6.2 Controladores Exemplo

```ruby
# app/controllers/anamneses_controller.rb
class AnamnesesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_anamnesis, except: [:index, :new, :create]
  
  def index
    @anamneses = current_user.anamneses
  end
  
  def new
    @anamnesis = current_user.anamneses.new
    redirect_to step1_anamnesis_path(@anamnesis)
  end

  def create
    @anamnesis = current_user.anamneses.new(anamnesis_params)
    
    if @anamnesis.save
      redirect_to step1_anamnesis_path(@anamnesis)
    else
      render :new
    end
  end
  
  def step1
    # Renderiza o formulário do passo 1
  end
  
  def save_step1
    if @anamnesis.update(step1_params)
      redirect_to step2_anamnesis_path(@anamnesis)
    else
      render :step1
    end
  end
  
  # Métodos similares para os passos 2-5
  
  private
  
  def set_anamnesis
    @anamnesis = current_user.anamneses.find(params[:id])
  end
  
  def anamnesis_params
    params.require(:anamnesis).permit(:user_id)
  end
  
  def step1_params
    params.require(:anamnesis).permit(
      health_data: [:height, :weight, :date_of_birth, :gender]
    )
  end
  
  # Métodos similares para os parâmetros dos passos 2-5
end

# app/controllers/food_plans_controller.rb
class FoodPlansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_food_plan, except: [:index, :new, :create]
  
  def index
    @food_plans = current_user.food_plans
  end
  
  def show
    # Mostra o plano alimentar
  end
  
  def create
    @anamnesis = current_user.anamneses.find(params[:anamnesis_id])
    @food_plan = FoodPlanGenerator.new(@anamnesis).generate
    
    if @food_plan.save
      redirect_to @food_plan, notice: 'Plano alimentar gerado com sucesso!'
    else
      redirect_to @anamnesis, alert: 'Erro ao gerar plano alimentar.'
    end
  end
  
  def download_pdf
    pdf = FoodPlanPdf.new(@food_plan).render
    send_data pdf, filename: "plano_alimentar_#{current_user.name}.pdf", type: 'application/pdf'
  end
  
  def send_email
    FoodPlanMailer.with(user: current_user, food_plan: @food_plan).send_plan.deliver_later
    redirect_to @food_plan, notice: 'Plano alimentar enviado por e-mail!'
  end
  
  private
  
  def set_food_plan
    @food_plan = current_user.food_plans.find(params[:id])
  end
end
```

## 7. Integração de TailwindCSS 4 e Stimulus.js

### 7.1 Configuração do TailwindCSS 4

```ruby
# Gemfile
gem 'tailwindcss-rails', '~> 4.0'
```

```bash
# Terminal
bin/rails tailwindcss:install
```

```js
// tailwind.config.js
module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,rb}'
  ],
  theme: {
    extend: {
      colors: {
        'primary': '#2C7D54',
        'primary-light': '#EAF5F0',
        'secondary': '#37B76A',
        'accent': '#F9A826',
      },
      borderRadius: {
        DEFAULT: '8px',
      },
      boxShadow: {
        DEFAULT: '0 4px 12px rgba(0, 0, 0, 0.08)',
        'hover': '0 6px 16px rgba(0, 0, 0, 0.12)',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

### 7.2 Configuração do Stimulus.js

```ruby
# Gemfile
gem 'stimulus-rails'
```

```bash
# Terminal
bin/rails stimulus:install
```

### 7.3 Exemplo de Controlador Stimulus

```js
// app/javascript/controllers/anamnesis_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "step", "progressBar", "nextButton", "backButton" ]
  static values = { currentStep: Number, totalSteps: Number }

  connect() {
    this.updateProgressBar()
    this.validateCurrentStep()
  }

  next() {
    if (this.validateCurrentStep()) {
      this.currentStepValue++
      this.updateProgressBar()
      this.showCurrentStep()
    }
  }

  back() {
    if (this.currentStepValue > 1) {
      this.currentStepValue--
      this.updateProgressBar()
      this.showCurrentStep()
    }
  }

  showCurrentStep() {
    this.stepTargets.forEach((step, index) => {
      step.classList.toggle("hidden", index !== this.currentStepValue - 1)
    })
    
    this.backButtonTarget.disabled = this.currentStepValue === 1
    this.updateNextButtonText()
  }

  updateProgressBar() {
    const progress = (this.currentStepValue - 1) / (this.totalStepsValue - 1) * 100
    this.progressBarTarget.style.width = `${progress}%`
  }

  updateNextButtonText() {
    this.nextButtonTarget.textContent = 
      this.currentStepValue === this.totalStepsValue ? "Finalizar" : "Próximo"
  }

  validateCurrentStep() {
    // Implementação da validação do formulário atual
    return true
  }
}
```

## 8. Componentes do Sistema

### 8.1 Componente de Formulário por Etapas

```ruby
# app/components/stepped_form_component.rb
class SteppedFormComponent < ViewComponent::Base
  renders_many :steps, "StepComponent"
  
  def initialize(form:, current_step:, total_steps:)
    @form = form
    @current_step = current_step
    @total_steps = total_steps
  end
  
  private
  
  class StepComponent < ViewComponent::Base
    def initialize(title:, description:, step_number:)
      @title = title
      @description = description
      @step_number = step_number
    end
    
    def render?
      true
    end
  end
end
```

```erb
<!-- app/components/stepped_form_component.html.erb -->
<div data-controller="anamnesis-form" 
     data-anamnesis-form-current-step-value="<%= @current_step %>"
     data-anamnesis-form-total-steps-value="<%= @total_steps %>">
  
  <div class="progress-container">
    <div class="progress-steps">
      <% @total_steps.times do |i| %>
        <div class="step <%= i+1 < @current_step ? 'completed' : '' %> <%= i+1 == @current_step ? 'active' : '' %>">
          <div class="step-icon"><%= i+1 %></div>
          <div class="step-label"><%= steps[i].title %></div>
        </div>
      <% end %>
    </div>
    
    <div class="progress-bar-container">
      <div class="progress-bar" data-anamnesis-form-target="progressBar" style="width: <%= (@current_step - 1.0) / (@total_steps - 1) * 100 %>%"></div>
    </div>
  </div>
  
  <%= form_with(model: @form, html: { class: "form-container" }) do |f| %>
    <% steps.each_with_index do |step, index| %>
      <div data-anamnesis-form-target="step" class="form-content <%= index+1 == @current_step ? '' : 'hidden' %>">
        <h2 class="step-title"><%= step.title %></h2>
        <p class="step-description"><%= step.description %></p>
        
        <%= content %>
        
        <div class="form-actions">
          <button type="button" data-anamnesis-form-target="backButton" data-action="click->anamnesis-form#back" class="btn btn-back" <%= @current_step == 1 ? 'disabled' : '' %>>Voltar</button>
          <button type="button" data-anamnesis-form-target="nextButton" data-action="click->anamnesis-form#next" class="btn btn-next">
            <%= @current_step == @total_steps ? 'Finalizar' : 'Próximo' %>
          </button>
        </div>
      </div>
    <% end %>
  <% end %>
</div>
```

### 8.2 Serviço para Geração de Plano Alimentar

```ruby
# app/services/food_plan_generator.rb
class FoodPlanGenerator
  def initialize(anamnesis)
    @anamnesis = anamnesis
    @user = anamnesis.user
  end
  
  def generate
    food_plan = FoodPlan.new(
      user: @user,
      anamnesis: @anamnesis,
      caloric_goal: calculate_caloric_goal,
      macronutrient_distribution: calculate_macronutrients
    )
    
    create_meals(food_plan)
    create_water_plan(food_plan)
    create_grocery_list(food_plan)
    
    food_plan
  end
  
  private
  
  def calculate_caloric_goal
    # Algoritmo para calcular necessidades calóricas
    # Exemplo simplificado:
    health_data = @anamnesis.health_data
    height = health_data['height'].to_f
    weight = health_data['weight'].to_f
    age = calculate_age(health_data['date_of_birth'])
    gender = health_data['gender']
    activity_level = @anamnesis.physical_activity['level']
    
    # Fórmula de Harris-Benedict para calcular Metabolismo Basal
    bmr = if gender == 'female'
            655 + (9.6 * weight) + (1.8 * height) - (4.7 * age)
          else
            66 + (13.7 * weight) + (5 * height) - (6.8 * age)
          end
    
    # Ajustar para nível de atividade
    tdee = case activity_level
           when 'sedentary'
             bmr * 1.2
           when 'lightly_active'
             bmr * 1.375
           when 'moderately_active'
             bmr * 1.55
           when 'very_active'
             bmr * 1.725
           when 'extra_active'
             bmr * 1.9
           else
             bmr * 1.375
           end
    
    # Ajustar para objetivo
    goal = @anamnesis.goals['main']
    case goal
    when 'lose_weight'
      tdee - 500
    when 'gain_muscle'
      tdee + 300
    else
      tdee
    end
  end
  
  def calculate_macronutrients
    # Algoritmo para calcular distribuição de macronutrientes
    # Exemplo simplificado:
    goal = @anamnesis.goals['main']
    
    case goal
    when 'lose_weight'
      {
        protein_percentage: 35,
        carbs_percentage: 40,
        fat_percentage: 25
      }
    when 'gain_muscle'
      {
        protein_percentage: 30,
        carbs_percentage: 50,
        fat_percentage: 20
      }
    else
      {
        protein_percentage: 25,
        carbs_percentage: 50,
        fat_percentage: 25
      }
    end
  end
  
  def create_meals(food_plan)
    # Criação das refeições com base nas preferências
    meals_data = [
      {
        name: 'Café da Manhã',
        time: '07:00',
        meal_type: :breakfast,
        objective: 'Quebrar o jejum noturno e fornecer energia estável para a manhã'
      },
      {
        name: 'Lanche da Manhã',
        time: '10:00',
        meal_type: :morning_snack,
        objective: 'Manter energia e controlar a fome até o almoço'
      },
      {
        name: 'Almoço',
        time: '13:00',
        meal_type: :lunch,
        objective: 'Refeição principal com alta densidade nutricional'
      },
      {
        name: 'Lanche da Tarde',
        time: '16:00',
        meal_type: :afternoon_snack,
        objective: 'Fornecer energia para o período da tarde'
      },
      {
        name: 'Jantar',
        time: '19:00',
        meal_type: :dinner,
        objective: 'Promover recuperação e preparo para o descanso noturno'
      }
    ]
    
    meals_data.each do |meal_data|
      meal = food_plan.meals.build(meal_data)
      create_food_items_for_meal(meal)
    end
  end
  
  def create_food_items_for_meal(meal)
    # Lógica para selecionar alimentos para cada refeição
    # baseados nas preferências e restrições
    # Implementação detalhada aqui...
  end
  
  def create_water_plan(food_plan)
    # Cálculo da recomendação de água com base no peso e atividade
    weight = @anamnesis.health_data['weight'].to_f
    activity_level = @anamnesis.physical_activity['level']
    
    # Base: 35ml por kg de peso
    daily_recommendation = weight * 35
    
    # Ajustar baseado no nível de atividade
    case activity_level
    when 'very_active', 'extra_active'
      daily_recommendation += 500
    when 'moderately_active'
      daily_recommendation += 300
    end
    
    # Arredondar para múltiplos de 100ml
    daily_recommendation = (daily_recommendation / 100).round * 100
    
    food_plan.build_water_plan(
      daily_recommendation: daily_recommendation,
      distribution: {
        morning: "#{(daily_recommendation * 0.4).to_i}ml",
        afternoon: "#{(daily_recommendation * 0.4).to_i}ml",
        evening: "#{(daily_recommendation * 0.2).to_i}ml"
      }
    )
  end
  
  def create_grocery_list(food_plan)
    # Gerar lista de compras com base nos alimentos do plano
    # Implementação detalhada aqui...
  end
  
  def calculate_age(dob)
    # Calcula a idade com base na data de nascimento
    now = Time.now.utc.to_date
    dob = Date.parse(dob)
    now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
  end
end
```

### 8.3 Classe para Geração de PDF

```ruby
# app/pdfs/food_plan_pdf.rb
class FoodPlanPdf
  include Prawn::View
  
  def initialize(food_plan)
    @food_plan = food_plan
    @document = Prawn::Document.new(
      page_size: "A4",
      margin: [50, 50, 50, 50]
    )
    generate
  end
  
  def generate
    header
    summary
    diagnostic
    meal_goals
    weekly_plan
    hydration_plan
    grocery_list
    recipes
    implementation_tips
    footer
  end
  
  private
  
  def header
    # Implementação do cabeçalho do PDF
  end
  
  def summary
    # Seção de resumo personalizado
  end
  
  def diagnostic
    # Seção de diagnóstico
  end
  
  # Implementação de outras seções do PDF...
end
```

## 9. Fluxo de Trabalho e Implementação

### 9.1 Estrutura de Diretórios

```
app/
├── assets/
│   └── stylesheets/
│       └── application.tailwind.css
├── components/
│   ├── stepped_form_component.rb
│   └── stepped_form_component.html.erb
├── controllers/
│   ├── anamneses_controller.rb
│   ├── food_plans_controller.rb
│   └── ...
├── javascript/
│   ├── controllers/
│   │   ├── anamnesis_form_controller.js
│   │   └── ...
│   └── application.js
├── models/
│   ├── user.rb
│   ├── anamnesis.rb
│   └── ...
├── pdfs/
│   └── food_plan_pdf.rb
├── services/
│   └── food_plan_generator.rb
└── views/
    ├── anamneses/
    │   ├── step1.html.erb
    │   └── ...
    ├── food_plans/
    │   ├── show.html.erb
    │   └── ...
    └── ...
```

### 9.2 Implementação de Turbo Frames para a Navegação de Etapas

```erb
<!-- app/views/anamneses/step1.html.erb -->
<%= turbo_frame_tag "anamnesis_form" do %>
  <%= render SteppedFormComponent.new(form: @anamnesis, current_step: 1, total_steps: 5) do |c| %>
    <% c.step(title: "Dados Pessoais", description: "Vamos começar com algumas informações básicas para personalizar seu plano nutricional.", step_number: 1) do %>
      <!-- Conteúdo do formulário do passo 1 -->
    <% end %>
    
    <% c.step(title: "Saúde e Hábitos", description: "...", step_number: 2) do %>
      <!-- Conteúdo do passo 2 -->
    <% end %>
    
    <!-- Outras etapas... -->
  <% end %>
<% end %>
```

## 10. Cronograma de Implementação Sugerido

### Fase 1: Setup e Estrutura Básica (2 semanas)
- Configuração do Rails 8 com PostgreSQL
- Implementação do TailwindCSS 4 e Stimulus.js
- Modelagem do banco de dados
- Configuração do sistema de autenticação

### Fase 2: Implementação do Questionário (3 semanas)
- Desenvolvimento dos componentes do formulário em etapas
- Implementação dos controladores Stimulus para gerenciar o formulário
- Integração com Turbo para navegação fluida
- Desenvolvimento dos controladores do Rails para salvar os dados

### Fase 3: Sistema de Geração de Planos (4 semanas)
- Implementação do serviço de geração de planos alimentares
- Desenvolvimento do sistema de criação de PDFs
- Configuração do sistema de envio de emails
- Testes de integração

### Fase 4: Finalização e Polimento (2 semanas)
- Implementação de recursos adicionais
- Otimização de desempenho
- Testes de sistema
- Documentação

## 11. Considerações Finais

Este documento de requisitos estabelece as bases para o desenvolvimento do sistema de planos alimentares personalizados usando o stack moderno Rails 8, TailwindCSS 4 e Stimulus.js.

A abordagem full-stack do Rails 8 combinada com a interatividade do Stimulus.js e a flexibilidade do TailwindCSS 4 proporcionará um sistema eficiente, responsivo e com excelente experiência de usuário, eliminando a necessidade de um framework JavaScript separado para o frontend, simplificando a arquitetura e acelerando o desenvolvimento.

A implementação modular e o uso de componentes permitirão expansões e melhorias futuras conforme necessário, garantindo a longevidade do sistema.