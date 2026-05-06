import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "actionBar", "count", "form"]

  connect() {
    this.updateUI()
  }

  toggleAll() {
    const isChecked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })
    this.updateUI()
  }

  toggleItem() {
    const allChecked = this.checkboxTargets.every(checkbox => checkbox.checked)
    this.selectAllTarget.checked = allChecked
    this.updateUI()
  }

  updateUI() {
    const selectedCount = this.checkboxTargets.filter(checkbox => checkbox.checked).length
    
    if (selectedCount > 0) {
      this.actionBarTarget.classList.remove("translate-y-full", "opacity-0")
      this.actionBarTarget.classList.add("translate-y-0", "opacity-100")
      this.countTarget.textContent = selectedCount
    } else {
      this.actionBarTarget.classList.add("translate-y-full", "opacity-0")
      this.actionBarTarget.classList.remove("translate-y-0", "opacity-100")
    }
  }

  submit(event) {
    const selectedIds = this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value)

    if (selectedIds.length === 0) {
      alert("Please select at least one business.")
      event.preventDefault()
      return
    }

    // Create hidden fields for each selected ID in the form
    selectedIds.forEach(id => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "business_ids[]"
      input.value = id
      this.formTarget.appendChild(input)
    })
  }
}
