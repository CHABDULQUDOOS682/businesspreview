import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static classes = ["selected", "idle"]

  choose(event) {
    this.inputTarget.value = event.params.value

    this.element.querySelectorAll("[data-slot-option]").forEach((btn) => {
      this.applyIdle(btn)
    })
    this.applySelected(event.currentTarget)
  }

  selectDate(event) {
    this.element.querySelectorAll(".date-link").forEach((btn) => {
      btn.classList.remove("bg-[#213885]", "text-white", "shadow-lg", "shadow-[#213885]/20")
      btn.classList.add("bg-[#081849]/5", "text-[#081849]")
    })
    event.currentTarget.classList.add("bg-[#213885]", "text-white", "shadow-lg", "shadow-[#213885]/20")
    event.currentTarget.classList.remove("bg-[#081849]/5", "text-[#081849]")
  }

  validate(event) {
    if (!this.inputTarget.value) {
      event.preventDefault()
      alert("Please select an available time slot before continuing.")
    }
  }

  applySelected(button) {
    if (this.hasSelectedClass) {
      button.classList.remove(...this.idleClasses)
      button.classList.add(...this.selectedClasses)
      return
    }

    button.classList.remove("bg-white/50", "text-[#081849]", "bg-white", "text-slate-900", "ring-slate-300")
    button.classList.add("bg-[#213885]", "text-white", "border-[#213885]")
  }

  applyIdle(button) {
    if (this.hasIdleClass) {
      button.classList.remove(...this.selectedClasses)
      button.classList.add(...this.idleClasses)
      return
    }

    button.classList.remove("bg-[#213885]", "text-white", "border-[#213885]", "bg-indigo-600", "ring-indigo-600")
    button.classList.add("bg-white/50", "text-[#081849]")
  }
}
