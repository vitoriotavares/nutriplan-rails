// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails"
import "./controllers"

// Make Turbo available globally
window.Turbo = Turbo
