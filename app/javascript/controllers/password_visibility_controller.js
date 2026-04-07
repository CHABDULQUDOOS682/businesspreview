import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "label"]

  toggle() {
    const shouldReveal = this.inputTarget.type === "password"

    this.inputTarget.type = shouldReveal ? "text" : "password"

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = shouldReveal ? "Hide" : "Show"
    }
  }
}
