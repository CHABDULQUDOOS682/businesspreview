import { Controller } from "@hotwired/stimulus"

// Keeps browser tab title + installed PWA app-icon badge in sync with unread count.
export default class extends Controller {
  static values = {
    count: { type: Number, default: 0 },
    baseTitle: { type: String, default: "DevDeBizz | Admin" },
    serviceWorkerUrl: { type: String, default: "/admin/service-worker.js" }
  }

  connect() {
    this.#registerServiceWorker()
    this.#apply()
  }

  countValueChanged() {
    this.#apply()
  }

  #registerServiceWorker() {
    if (!("serviceWorker" in navigator)) return
    navigator.serviceWorker
      .register(this.serviceWorkerUrlValue, { scope: "/admin" })
      .catch(() => {})
  }

  #apply() {
    const count = Math.max(0, Number(this.countValue) || 0)
    document.title = count > 0 ? `(${count}) ${this.baseTitleValue}` : this.baseTitleValue
    this.#setAppBadge(count)
  }

  #setAppBadge(count) {
    if (!("setAppBadge" in navigator)) return

    if (count > 0) {
      navigator.setAppBadge(count).catch(() => {})
    } else if ("clearAppBadge" in navigator) {
      navigator.clearAppBadge().catch(() => {})
    }
  }
}
