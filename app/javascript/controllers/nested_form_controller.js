// app/javascript/controllers/nested_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["items", "item"]
  
  connect() {
    console.log("NestedForm controller connected")
  }
  
  addItem(event) {
    event.preventDefault()
    
    // Obter o timestamp para criar IDs únicos
    const timestamp = new Date().getTime()
    
    // Obter o template para um novo item alimentar
    const template = this.foodItemTemplate(timestamp)
    
    // Adicionar o template ao final da lista de itens
    this.itemsTarget.insertAdjacentHTML('beforeend', template)
  }
  
  removeItem(event) {
    event.preventDefault()
    
    const itemElement = event.target.closest('[data-nested-form-target="item"]')
    
    // Se o elemento tem um ID (já existe no banco), marcar para destruição
    const hiddenField = itemElement.querySelector('input[name*="_destroy"]')
    if (hiddenField) {
      hiddenField.value = "1"
      itemElement.style.display = "none"
    } else {
      // Se não tem ID (novo elemento), remover do DOM
      itemElement.remove()
    }
  }
  
  foodItemTemplate(timestamp) {
    // Obter o índice da refeição atual
    const mealIndex = this.element.closest('[data-food-plan-form-target="meal"]')
                          .querySelector('input[name*="[name]"]')
                          .name.match(/\[meals_attributes\]\[(\d+|[a-z0-9]+)\]/)[1]
    
    return `
      <div class="food-item-fields bg-white p-3 rounded-md mb-3 border border-gray-200 shadow-sm"
           data-nested-form-target="item"
           data-controller="food-item">
        
        <div class="flex justify-between items-start">
          <div class="flex-1">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1" 
                       for="food_plan_meals_attributes_${mealIndex}_food_items_attributes_${timestamp}_name">Alimento</label>
                <input class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500" 
                       type="text" 
                       name="food_plan[meals_attributes][${mealIndex}][food_items_attributes][${timestamp}][name]" 
                       id="food_plan_meals_attributes_${mealIndex}_food_items_attributes_${timestamp}_name">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1" 
                       for="food_plan_meals_attributes_${mealIndex}_food_items_attributes_${timestamp}_quantity">Quantidade</label>
                <input class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500" 
                       type="number" 
                       step="0.1" 
                       min="0" 
                       name="food_plan[meals_attributes][${mealIndex}][food_items_attributes][${timestamp}][quantity]" 
                       id="food_plan_meals_attributes_${mealIndex}_food_items_attributes_${timestamp}_quantity">
              </div>
              
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1" 
                       for="food_plan_meals_attributes_${mealIndex}_food_items_attributes_${timestamp}_unit">Unidade</label>
                <select class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500" 
                        name="food_plan[meals_attributes][${mealIndex}][food_items_attributes][${timestamp}][unit]" 
                        id="food_plan_meals_attributes_${mealIndex}_food_items_attributes_${timestamp}_unit">
                  <option value="">Selecione</option>
                  <option value="g">Gramas</option>
                  <option value="ml">Mililitros</option>
                  <option value="colher_sopa">Colher de sopa</option>
                  <option value="colher_cha">Colher de chá</option>
                  <option value="xicara">Xícara</option>
                  <option value="unidade">Unidade</option>
                  <option value="fatia">Fatia</option>
                </select>
              </div>
            </div>
          </div>
          
          <div class="ml-3 flex">
            <input type="hidden" 
                   name="food_plan[meals_attributes][${mealIndex}][food_items_attributes][${timestamp}][_destroy]" 
                   id="food_plan_meals_attributes_${mealIndex}_food_items_attributes_${timestamp}__destroy" 
                   value="0">
            <button type="button" 
                    class="px-2 py-1 bg-red-100 text-red-700 rounded-md flex items-center text-sm"
                    data-action="click->nested-form#removeItem">
              <i class="fas fa-times"></i>
            </button>
          </div>
        </div>
        
        <div class="mt-3">
          <button type="button"
                  class="text-sm text-blue-600 flex items-center"
                  data-action="click->food-item#toggleSubstitutes">
            <i class="fas fa-exchange-alt mr-1"></i>
            <span data-food-item-target="toggleText">Mostrar opções de substituição</span>
          </button>
          
          <div class="mt-2 bg-gray-50 p-3 rounded-md border border-gray-200 hidden" data-food-item-target="substitutesSection">
            <h5 class="text-sm font-medium text-gray-700 mb-2">Opções de Substituição</h5>
            
            <div data-food-item-target="substitutesList">
              <!-- Os substitutos serão adicionados aqui -->
            </div>
            
            <button type="button"
                    class="mt-2 px-2 py-1 bg-blue-100 text-blue-700 rounded-md text-xs flex items-center"
                    data-action="click->food-item#addSubstitute">
              <i class="fas fa-plus mr-1"></i> Adicionar Substituto
            </button>
          </div>
        </div>
      </div>
    `
  }
}
