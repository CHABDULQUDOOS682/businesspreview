import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "button"]

  connect() {
    this.activeClass = "bg-[#213885] text-[#ECDFD2] border-[#213885]"
    this.inactiveClass = "bg-[#081849]/5 text-[#081849]/70 border-[#081849]/15"
  }

  filter(event) {
    const category = event.currentTarget.dataset.category
    
    // Check if View Transitions API is supported
    if (!document.startViewTransition) {
      this.performFilter(category, event.currentTarget)
      return
    }

    document.startViewTransition(() => {
      this.performFilter(category, event.currentTarget)
    })
  }

  performFilter(category, activeBtn) {
    // Update button states
    this.buttonTargets.forEach(btn => {
      const isActive = btn === activeBtn
      btn.className = `rounded-full border px-5 py-2 text-sm font-medium transition-all duration-300 ${isActive ? this.activeClass : this.inactiveClass}`
    })

    // Filter items
    this.itemTargets.forEach(item => {
      const itemCategory = item.dataset.category
      const shouldShow = category === "All" || itemCategory === category
      
      if (shouldShow) {
        item.classList.remove("hidden")
      } else {
        item.classList.add("hidden")
      }
    })
  }
}
