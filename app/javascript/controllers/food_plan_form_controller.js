// app/javascript/controllers/food_plan_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["meals", "meal"]
  
  connect() {
    console.log("FoodPlanForm controller connected")
    
    // Adicionar validação ao formulário antes do envio
    const form = this.element
    form.addEventListener('submit', this.validateForm.bind(this))
  }
  
  addMeal(event) {
    event.preventDefault()
    
    // Obter o timestamp para criar IDs únicos
    const timestamp = new Date().getTime()
    
    // Obter o template para uma nova refeição
    const template = this.mealTemplate(timestamp)
    
    // Adicionar o template ao final da lista de refeições
    this.mealsTarget.insertAdjacentHTML('beforeend', template)
  }
  
  removeMeal(event) {
    event.preventDefault()
    
    const mealElement = event.target.closest('[data-food-plan-form-target="meal"]')
    
    // Se o elemento tem um ID (já existe no banco), marcar para destruição
    const hiddenField = mealElement.querySelector('input[name*="_destroy"]')
    if (hiddenField) {
      hiddenField.value = "1"
      mealElement.style.display = "none"
    } else {
      // Se não tem ID (novo elemento), remover do DOM
      mealElement.remove()
    }
  }
  
  validateForm(event) {
    // Remover mensagens de erro anteriores
    const existingErrors = document.querySelectorAll('.validation-error')
    existingErrors.forEach(error => error.remove())
    
    let isValid = true
    
    // Verificar se todos os itens alimentares visíveis têm uma unidade selecionada
    const foodItemUnits = document.querySelectorAll('select[name*="[food_items_attributes]"][name*="[unit]"]')
    
    foodItemUnits.forEach(unitSelect => {
      // Verificar apenas itens visíveis (não marcados para exclusão)
      const foodItemContainer = unitSelect.closest('[data-nested-form-target="item"]')
      if (foodItemContainer && foodItemContainer.style.display !== 'none') {
        const destroyField = foodItemContainer.querySelector('input[name*="_destroy"]')
        
        // Se o item não está marcado para exclusão e a unidade não está selecionada
        if ((!destroyField || destroyField.value === "0") && !unitSelect.value) {
          isValid = false
          
          // Adicionar classe de erro ao select
          unitSelect.classList.add('border-red-500', 'ring-1', 'ring-red-500')
          
          // Adicionar mensagem de erro abaixo do select
          const errorMessage = document.createElement('div')
          errorMessage.className = 'text-red-500 text-xs mt-1 validation-error'
          errorMessage.textContent = 'Selecione uma unidade'
          unitSelect.parentNode.appendChild(errorMessage)
        } else {
          // Remover classes de erro se estiver válido
          unitSelect.classList.remove('border-red-500', 'ring-1', 'ring-red-500')
        }
      }
    })
    
    if (!isValid) {
      event.preventDefault()
      
      // Exibir mensagem de erro geral no topo do formulário
      const errorContainer = document.createElement('div')
      errorContainer.className = 'bg-red-50 text-red-700 p-4 rounded-md mb-4 validation-error'
      errorContainer.innerHTML = `
        <h3 class="font-semibold mb-2">Por favor, corrija os erros abaixo:</h3>
        <ul class="list-disc pl-5">
          <li>Todos os alimentos devem ter uma unidade selecionada</li>
        </ul>
      `
      
      // Inserir no início do formulário
      const firstSection = this.element.querySelector('.bg-white')
      if (firstSection) {
        firstSection.insertBefore(errorContainer, firstSection.firstChild.nextSibling)
      }
      
      // Rolar para o topo do formulário
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }
  
  mealTemplate(timestamp) {
    return `
      <div class="meal-fields bg-gray-50 p-4 rounded-md mb-4 border border-gray-200" 
           data-controller="nested-form"
           data-food-plan-form-target="meal">
        
        <div class="flex justify-between items-start mb-4">
          <div class="flex-1">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1" for="food_plan_meals_attributes_${timestamp}_name">Nome da Refeição</label>
                <input class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500" 
                       type="text" 
                       name="food_plan[meals_attributes][${timestamp}][name]" 
                       id="food_plan_meals_attributes_${timestamp}_name">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1" for="food_plan_meals_attributes_${timestamp}_time">Horário</label>
                <input class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500" 
                       type="time" 
                       name="food_plan[meals_attributes][${timestamp}][time]" 
                       id="food_plan_meals_attributes_${timestamp}_time">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1" for="food_plan_meals_attributes_${timestamp}_meal_type">Tipo</label>
                <select class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500" 
                        name="food_plan[meals_attributes][${timestamp}][meal_type]" 
                        id="food_plan_meals_attributes_${timestamp}_meal_type">
                  <option value="">Selecione o tipo</option>
                  <option value="breakfast">Café da manhã</option>
                  <option value="morning_snack">Lanche da manhã</option>
                  <option value="lunch">Almoço</option>
                  <option value="afternoon_snack">Lanche da tarde</option>
                  <option value="dinner">Jantar</option>
                  <option value="evening_snack">Ceia</option>
                </select>
              </div>
            </div>
            
            <div class="mt-3">
              <label class="block text-sm font-medium text-gray-700 mb-1" for="food_plan_meals_attributes_${timestamp}_objective">Objetivo da Refeição</label>
              <textarea class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500" 
                        rows="2" 
                        name="food_plan[meals_attributes][${timestamp}][objective]" 
                        id="food_plan_meals_attributes_${timestamp}_objective"></textarea>
            </div>
          </div>
          
          <div class="ml-4 flex">
            <input type="hidden" name="food_plan[meals_attributes][${timestamp}][_destroy]" id="food_plan_meals_attributes_${timestamp}__destroy" value="0">
            <button type="button" 
                    class="px-2 py-1 bg-red-100 text-red-700 rounded-md flex items-center text-sm"
                    data-action="click->food-plan-form#removeMeal">
              <i class="fas fa-trash mr-1"></i> Remover
            </button>
          </div>
        </div>
        
        <div class="mt-4">
          <div class="flex items-center justify-between mb-3">
            <h4 class="font-medium text-gray-700">Alimentos</h4>
            <button type="button" 
                    class="px-2 py-1 bg-green-100 text-green-700 rounded-md flex items-center text-sm"
                    data-action="click->nested-form#addItem">
              <i class="fas fa-plus mr-1"></i> Adicionar Alimento
            </button>
          </div>
          
          <div data-nested-form-target="items">
            <!-- Os itens alimentares serão adicionados aqui -->
          </div>
        </div>
      </div>
    `
  }
}
