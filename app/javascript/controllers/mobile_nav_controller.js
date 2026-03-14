import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button"]

  connect() {
    // Ensure a consistent initial state (and avoid Turbo caching an "open" menu).
    this.close()
  }

  toggle() {
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.toggle("hidden")
    this.#syncAria()
  }

  close() {
    if (!this.hasPanelTarget) return

    this.panelTarget.classList.add("hidden")
    this.#syncAria()
  }

  #syncAria() {
    if (!this.hasButtonTarget || !this.hasPanelTarget) return

    const open = !this.panelTarget.classList.contains("hidden")
    this.buttonTarget.setAttribute("aria-expanded", String(open))
  }
}

