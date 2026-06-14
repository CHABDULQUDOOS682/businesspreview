import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "label" ]
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      if (this.hasLabelTarget) {
        const original = this.labelTarget.textContent
        this.labelTarget.textContent = "Copied!"
        setTimeout(() => {
          this.labelTarget.textContent = original
        }, 1500)
      }
    } catch (_error) {
      window.prompt("Copy this link:", this.textValue)
    }
  }
}
