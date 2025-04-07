// app/javascript/controllers/food_item_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleText", "substitutesSection", "substitutesList"]
  
  connect() {
    console.log("FoodItem controller connected")
  }
  
  toggleSubstitutes(event) {
    event.preventDefault()
    
    const isHidden = this.substitutesSectionTarget.classList.contains('hidden')
    
    if (isHidden) {
      this.substitutesSectionTarget.classList.remove('hidden')
      this.toggleTextTarget.textContent = "Ocultar opções de substituição"
    } else {
      this.substitutesSectionTarget.classList.add('hidden')
      this.toggleTextTarget.textContent = "Mostrar opções de substituição"
    }
  }
  
  addSubstitute(event) {
    event.preventDefault()
    
    // Obter o timestamp para criar IDs únicos
    const timestamp = new Date().getTime()
    
    // Obter o template para um novo substituto
    const template = this.substituteTemplate(timestamp)
    
    // Adicionar o template ao final da lista de substitutos
    this.substitutesListTarget.insertAdjacentHTML('beforeend', template)
  }
  
  removeSubstitute(event) {
    event.preventDefault()
    
    const substituteElement = event.target.closest('.substitute-item')
    substituteElement.remove()
  }
  
  substituteTemplate(timestamp) {
    // Obter o nome do objeto do formulário para o item alimentar atual
    const foodItemInput = this.element.querySelector('input[name*="[name]"]')
    const objectName = foodItemInput.name.split('[name]')[0]
    
    return `
      <div class="substitute-item grid grid-cols-1 md:grid-cols-3 gap-2 mb-2">
        <div>
          <label class="block text-xs font-medium text-gray-700 mb-1">Alimento</label>
          <input class="w-full px-2 py-1 text-sm border border-gray-300 rounded-md" 
                 type="text" 
                 name="${objectName}[substitutes_attributes][${timestamp}][name]">
        </div>
        
        <div>
          <label class="block text-xs font-medium text-gray-700 mb-1">Quantidade</label>
          <input class="w-full px-2 py-1 text-sm border border-gray-300 rounded-md" 
                 type="number" 
                 step="0.1" 
                 min="0" 
                 name="${objectName}[substitutes_attributes][${timestamp}][quantity]">
        </div>
        
        <div>
          <label class="block text-xs font-medium text-gray-700 mb-1">Unidade</label>
          <select class="w-full px-2 py-1 text-sm border border-gray-300 rounded-md" 
                  name="${objectName}[substitutes_attributes][${timestamp}][unit]">
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
        
        <button type="button" 
                class="px-1 py-0.5 bg-red-100 text-red-700 rounded text-xs inline-flex items-center mt-1"
                data-action="click->food-item#removeSubstitute">
          <i class="fas fa-times"></i>
        </button>
      </div>
    `
  }
}
