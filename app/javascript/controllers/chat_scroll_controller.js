import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "bottom"]

  connect() {
    this._autoScroll = true
    this._onScroll = () => this.#updateAutoScroll()

    if (this.hasListTarget) {
      this.listTarget.addEventListener("scroll", this._onScroll, { passive: true })

      this._observer = new MutationObserver(() => {
        if (this._autoScroll) this.scrollToBottom()
      })
      this._observer.observe(this.listTarget, { childList: true, subtree: true })
    }

    this.scrollToBottom()
  }

  disconnect() {
    if (this.hasListTarget && this._onScroll) {
      this.listTarget.removeEventListener("scroll", this._onScroll)
    }
    if (this._observer) this._observer.disconnect()
    this._observer = null
    this._onScroll = null
  }

  scrollToBottom() {
    if (!this.hasListTarget) return

    const attempt = () => {
      if (this.hasBottomTarget) {
        this.bottomTarget.scrollIntoView({ block: "end" })
      } else {
        this.listTarget.scrollTop = this.listTarget.scrollHeight
      }
    }

    // Turbo + layout can reset scroll position; retry a few times.
    requestAnimationFrame(() => attempt())
    requestAnimationFrame(() => requestAnimationFrame(() => attempt()))
    setTimeout(attempt, 0)
    setTimeout(attempt, 50)
    setTimeout(attempt, 200)
  }

  #updateAutoScroll() {
    if (!this.hasListTarget) return

    const el = this.listTarget
    const distanceFromBottom = el.scrollHeight - (el.scrollTop + el.clientHeight)
    this._autoScroll = distanceFromBottom <= 80
  }
}
