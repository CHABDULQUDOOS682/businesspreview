import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "bugFields", "pageUrl", "browser", "operatingSystem" ]
  static values = { bugType: { type: String, default: "bug" } }

  connect() {
    this.toggleBugFields()
    this.captureEnvironment()
  }

  toggleBugFields() {
    if (!this.hasBugFieldsTarget) return

    const typeField = this.element.querySelector("[name='feedback[feedback_type]']")
    const isBug = typeField?.value === this.bugTypeValue
    this.bugFieldsTarget.classList.toggle("hidden", !isBug)
  }

  captureEnvironment() {
    if (this.hasPageUrlTarget && !this.pageUrlTarget.value) {
      this.pageUrlTarget.value = window.location.href
    }

    if (this.hasBrowserTarget && !this.browserTarget.value) {
      this.browserTarget.value = navigator.userAgent
    }

    if (this.hasOperatingSystemTarget && !this.operatingSystemTarget.value) {
      this.operatingSystemTarget.value = navigator.platform || ""
    }
  }
}
