import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "actionBar", "count", "form"]

  connect() {
    this.update()
  }

  toggleAll(event) {
    const checked = event.currentTarget === this.selectAllTarget
      ? this.selectAllTarget.checked
      : false

    this.checkboxTargets.forEach((checkbox) => {
      checkbox.checked = checked
    })

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = checked
    }

    this.update()
  }

  toggleItem() {
    this.update()
  }

  submit(event) {
    this.syncHiddenInputs()
  }

  update() {
    const selected = this.checkboxTargets.filter((checkbox) => checkbox.checked)

    if (this.hasCountTarget) {
      this.countTarget.textContent = selected.length
    }

    if (this.hasSelectAllTarget && this.checkboxTargets.length > 0) {
      this.selectAllTarget.checked = selected.length === this.checkboxTargets.length
      this.selectAllTarget.indeterminate =
        selected.length > 0 && selected.length < this.checkboxTargets.length
    }

    if (!this.hasActionBarTarget) return

    if (selected.length > 0) {
      this.actionBarTarget.classList.remove("translate-y-full", "opacity-0", "pointer-events-none")
    } else {
      this.actionBarTarget.classList.add("translate-y-full", "opacity-0", "pointer-events-none")
    }
  }

  syncHiddenInputs() {
    if (!this.hasFormTarget) return

    this.formTarget.querySelectorAll('input[name="business_ids[]"]').forEach((input) => input.remove())

    this.checkboxTargets
      .filter((checkbox) => checkbox.checked)
      .forEach((checkbox) => {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = "business_ids[]"
        input.value = checkbox.value
        this.formTarget.appendChild(input)
      })
  }
}
