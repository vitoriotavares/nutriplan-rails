// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"

// Initialize Stimulus application
const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Import and register controllers
import DropdownController from "./controllers/dropdown_controller"
application.register("dropdown", DropdownController)

// Import other controllers as needed
// import HelloController from "./controllers/hello_controller"
// application.register("hello", HelloController)

// Make Turbo available globally
window.Turbo = Turbo
