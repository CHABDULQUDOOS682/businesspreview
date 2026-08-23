import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "kind",
    "subscriptionPackages",
    "projectPackages",
    "title",
    "scope",
    "pricing",
    "timeline",
    "termination",
    "amount",
    "subscriptionFees",
    "projectFees",
    "packageHint",
    "payloads"
  ]

  connect() {
    this.payloads = JSON.parse(this.payloadsTarget.textContent)
    this.syncVisiblePackages()
    this.applySelectedPackage()
  }

  kindChanged() {
    this.syncVisiblePackages()
    this.applySelectedPackage()
  }

  packageChanged() {
    this.applySelectedPackage()
  }

  syncVisiblePackages() {
    const isSubscription = this.kindTarget.value === "subscription"
    this.subscriptionPackagesTarget.classList.toggle("hidden", !isSubscription)
    this.projectPackagesTarget.classList.toggle("hidden", isSubscription)
    if (this.hasSubscriptionFeesTarget) {
      this.subscriptionFeesTarget.classList.toggle("hidden", !isSubscription)
    }
    if (this.hasProjectFeesTarget) {
      this.projectFeesTarget.classList.toggle("hidden", isSubscription)
    }
    if (this.hasPackageHintTarget) {
      this.packageHintTarget.textContent = isSubscription
        ? "Essential, Growth, or Business Pro"
        : "Starter, Business Growth, or Custom"
    }

    this.subscriptionPackagesTarget.disabled = !isSubscription
    this.projectPackagesTarget.disabled = isSubscription
  }

  applySelectedPackage() {
    const kind = this.kindTarget.value
    const select = kind === "subscription" ? this.subscriptionPackagesTarget : this.projectPackagesTarget
    const key = select.value
    const payload = this.payloads?.[kind]?.[key]
    if (!payload) return

    this.titleTarget.value = payload.title || ""
    this.scopeTarget.value = payload.scope_of_work || ""
    this.pricingTarget.value = payload.pricing_terms || ""
    this.timelineTarget.value = payload.timeline_terms || ""
    this.terminationTarget.value = payload.termination_terms || ""
    this.amountTarget.value = payload.amount_dollars ?? ""
  }
}
