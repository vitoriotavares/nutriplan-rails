# Seed para criar os planos iniciais do NutriPlan
# Execute com: rails db:seed:plans

puts "Criando planos..."

# Limpa planos existentes
Plan.destroy_all

# Plano Gratuito
free_plan = Plan.create!(
  name: "Gratuito",
  description: "Experimente o NutriPlan com recursos básicos. Ideal para quem está começando a jornada de alimentação saudável.",
  price: 0.00,
  food_plans_limit: 1,
  full_recipe_access: false,
  priority_support: false,
  active: true,
  is_default: true
)

# Plano Premium
premium_plan = Plan.create!(
  name: "Premium",
  description: "Acesso completo a todos os recursos do NutriPlan. Crie mais planos alimentares personalizados e tenha suporte prioritário.",
  price: 19.90,
  food_plans_limit: 3,
  full_recipe_access: true,
  priority_support: true,
  active: true,
  is_default: false
)

puts "Planos criados com sucesso!"
puts "Plano Gratuito (ID: #{free_plan.id})"
puts "Plano Premium (ID: #{premium_plan.id})"
