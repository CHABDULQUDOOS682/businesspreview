import { Controller } from "@hotwired/stimulus"

// Simple canvas signature pad (mouse + touch).
export default class extends Controller {
  static targets = ["canvas", "input", "emptyError"]

  connect() {
    this.drawing = false
    this.hasStroke = false
    this.ctx = this.canvasTarget.getContext("2d")
    this.resizeCanvas()
    this.clearCanvas()

    this._onResize = () => this.resizeCanvas()
    window.addEventListener("resize", this._onResize)
  }

  disconnect() {
    window.removeEventListener("resize", this._onResize)
  }

  resizeCanvas() {
    const canvas = this.canvasTarget
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    const width = canvas.offsetWidth || 600
    const height = 180
    const snapshot = this.hasStroke ? canvas.toDataURL("image/png") : null

    canvas.width = width * ratio
    canvas.height = height * ratio
    canvas.style.height = `${height}px`
    this.ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
    this.ctx.lineWidth = 2.25
    this.ctx.lineCap = "round"
    this.ctx.lineJoin = "round"
    this.ctx.strokeStyle = "#0f172a"

    if (snapshot) {
      const image = new Image()
      image.onload = () => this.ctx.drawImage(image, 0, 0, width, height)
      image.src = snapshot
    } else {
      this.clearCanvas()
    }
  }

  clearCanvas() {
    const canvas = this.canvasTarget
    this.ctx.clearRect(0, 0, canvas.width, canvas.height)
    this.ctx.fillStyle = "#ffffff"
    this.ctx.fillRect(0, 0, canvas.offsetWidth || canvas.width, 180)
    this.hasStroke = false
    this.inputTarget.value = ""
    if (this.hasEmptyErrorTarget) this.emptyErrorTarget.classList.add("hidden")
  }

  clear(event) {
    event.preventDefault()
    this.clearCanvas()
  }

  start(event) {
    event.preventDefault()
    this.drawing = true
    const point = this.point(event)
    this.ctx.beginPath()
    this.ctx.moveTo(point.x, point.y)
  }

  move(event) {
    if (!this.drawing) return
    event.preventDefault()
    const point = this.point(event)
    this.ctx.lineTo(point.x, point.y)
    this.ctx.stroke()
    this.hasStroke = true
  }

  end(event) {
    if (!this.drawing) return
    event.preventDefault()
    this.drawing = false
    this.persist()
  }

  persist() {
    if (!this.hasStroke) {
      this.inputTarget.value = ""
      return
    }
    this.inputTarget.value = this.canvasTarget.toDataURL("image/png")
  }

  validate(event) {
    this.persist()
    if (!this.inputTarget.value) {
      event.preventDefault()
      if (this.hasEmptyErrorTarget) this.emptyErrorTarget.classList.remove("hidden")
    }
  }

  point(event) {
    const rect = this.canvasTarget.getBoundingClientRect()
    const source = event.touches ? event.touches[0] : event
    return {
      x: source.clientX - rect.left,
      y: source.clientY - rect.top
    }
  }
}
