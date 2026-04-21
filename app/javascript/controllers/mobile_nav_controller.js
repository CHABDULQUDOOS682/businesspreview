import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "button"]

  connect() {
    // Ensure a consistent initial state (and avoid Turbo caching an "open" menu).
    this.close()
    this.boundSyncScrolled = this.syncScrolled.bind(this)
    window.addEventListener("scroll", this.boundSyncScrolled, { passive: true })
    this.syncScrolled()
  }

  disconnect() {
    window.removeEventListener("scroll", this.boundSyncScrolled)
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

  syncScrolled() {
    this.element.classList.toggle("home-header-scrolled", window.scrollY > 20)
  }

  #syncAria() {
    if (!this.hasButtonTarget || !this.hasPanelTarget) return

    const open = !this.panelTarget.classList.contains("hidden")
    this.buttonTarget.setAttribute("aria-expanded", String(open))
  }
}
