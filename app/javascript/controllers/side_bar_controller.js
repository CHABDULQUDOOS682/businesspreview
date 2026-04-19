import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.expand = this.expand.bind(this)
    this.collapse = this.collapse.bind(this)
    this.handleBeforeCache = this.collapse.bind(this)

    this.element.addEventListener("mouseenter", this.expand)
    this.element.addEventListener("mouseleave", this.collapse)
    document.addEventListener("turbo:before-cache", this.handleBeforeCache)

    this.collapse()
    this.setupHoverStates()
  }

  disconnect() {
    this.element.removeEventListener("mouseenter", this.expand)
    this.element.removeEventListener("mouseleave", this.collapse)
    document.removeEventListener("turbo:before-cache", this.handleBeforeCache)

    this.hoverBindings?.forEach(({ item, enter, leave }) => {
      item.removeEventListener("mouseenter", enter)
      item.removeEventListener("mouseleave", leave)
    })
  }

  expand() {
    this.element.classList.remove("sidebar-container--collapsed")
    this.element.classList.add("sidebar-container--expanded")
  }

  collapse() {
    this.element.classList.add("sidebar-container--collapsed")
    this.element.classList.remove("sidebar-container--expanded")
  }

  setupHoverStates() {
    this.hoverBindings = []

    this.element.querySelectorAll(".sidebar-item:not(.sidebar-item--current)").forEach((item) => {
      const icon = item.querySelector(".sidebar-item-icon")
      const label = item.querySelector(".sidebar-item-label")
      const accentBg = (item.dataset.accentBg || "").split(" ").filter(Boolean)
      const accentText = (item.dataset.accentText || "").split(" ").filter(Boolean)

      const enter = () => {
        if (accentBg.length > 0) item.classList.add(...accentBg)
        if (icon && accentText.length > 0) icon.classList.add(...accentText)
        if (label && accentText.length > 0) label.classList.add(...accentText)
      }

      const leave = () => {
        if (accentBg.length > 0) item.classList.remove(...accentBg)
        if (icon && accentText.length > 0) icon.classList.remove(...accentText)
        if (label && accentText.length > 0) label.classList.remove(...accentText)
      }

      item.addEventListener("mouseenter", enter)
      item.addEventListener("mouseleave", leave)

      this.hoverBindings.push({ item, enter, leave })
    })
  }
}
