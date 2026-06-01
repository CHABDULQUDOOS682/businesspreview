import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["subscriptionBtn", "subscriptionBadge", "projectBtn", "panel", "comparison"]

  connect() {
    this.show("subscription")
  }

  toggle(event) {
    this.show(event.currentTarget.dataset.type)
  }

  show(type) {
    const isSubscription = type === "subscription"

    this.subscriptionBtnTarget.className = this.buttonClasses(isSubscription)
    this.projectBtnTarget.className = this.buttonClasses(!isSubscription)
    this.subscriptionBadgeTarget.classList.toggle("hidden", !isSubscription)

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.type !== type)
    })

    this.comparisonTargets.forEach((comparison) => {
      comparison.classList.toggle("hidden", comparison.dataset.type !== type)
    })
  }

  buttonClasses(active) {
    const base = "rounded-full px-5 py-2 text-sm font-semibold transition-all duration-300"

    if (active) {
      return `${base} bg-[#213885] text-[#ECDFD2] shadow-md shadow-[#213885]/25`
    }

    return `${base} text-[#081849]/55 hover:text-[#081849]`
  }
}
