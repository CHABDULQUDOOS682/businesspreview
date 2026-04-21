import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.reset()
  }

  move(event) {
    if (window.matchMedia("(pointer: coarse)").matches) return

    const rect = this.element.getBoundingClientRect()
    const px = (event.clientX - rect.left) / rect.width
    const py = (event.clientY - rect.top) / rect.height
    const rotateY = (px - 0.5) * 14
    const rotateX = (0.5 - py) * 14

    this.element.style.transform = `perspective(1000px) translateY(-10px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.018)`
    this.element.style.boxShadow = `${-rotateY * 2}px ${rotateX * 2 + 32}px 70px -18px rgba(33, 56, 133, 0.34)`
  }

  leave() {
    this.reset()
  }

  reset() {
    this.element.style.transform = ""
    this.element.style.boxShadow = ""
  }
}
