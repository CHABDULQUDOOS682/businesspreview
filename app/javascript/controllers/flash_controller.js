import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progress"]

  connect() {
    // Entrance animation
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(20px) scale(0.95)"
    
    requestAnimationFrame(() => {
      this.element.style.opacity = "1"
      this.element.style.transform = "translateX(0) scale(1)"
    })

    // Progress bar animation
    if (this.hasProgressTarget) {
      setTimeout(() => {
        this.progressTarget.style.width = "0%"
      }, 50)
    }

    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // Exit animation
    this.element.style.transition = "all 0.5s cubic-bezier(0.4, 0, 0.2, 1)"
    this.element.style.opacity = "0"
    this.element.style.transform = "translateX(20px) scale(0.95)"
    this.element.style.filter = "blur(8px)"

    setTimeout(() => {
      this.element.remove()
    }, 500)
  }
}
