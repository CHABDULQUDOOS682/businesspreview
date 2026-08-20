import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "reportField", "notesField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const status = this.statusTarget.value

    if (this.hasReportFieldTarget) {
      this.reportFieldTarget.classList.toggle("hidden", status !== "done")
    }

    if (this.hasNotesFieldTarget) {
      this.notesFieldTarget.classList.toggle("hidden", status !== "completed")
    }
  }
}
