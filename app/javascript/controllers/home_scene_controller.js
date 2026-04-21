import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.leave()
  }

  move(event) {
    if (window.matchMedia("(pointer: coarse)").matches) return

    const x = ((event.clientX / window.innerWidth) - 0.5) * 20
    const y = ((event.clientY / window.innerHeight) - 0.5) * 20

    this.element.style.setProperty("--mx", `${x}px`)
    this.element.style.setProperty("--my", `${y}px`)
  }

  leave() {
    this.element.style.setProperty("--mx", "0px")
    this.element.style.setProperty("--my", "0px")
  }
}
