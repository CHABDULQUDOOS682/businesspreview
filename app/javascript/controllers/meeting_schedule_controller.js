import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "businessSelect", "clientName", "clientEmail", "clientPhone", "title", "duration" ]
  static values = { businesses: Object }

  connect() {
    if (this.hasBusinessSelectTarget && this.businessSelectTarget.value) {
      this.fillBusiness()
    }
  }

  fillBusiness() {
    const businessId = this.businessSelectTarget.value
    if (!businessId) return

    const business = this.businessesValue[businessId]
    if (!business) return

    if (this.hasClientNameTarget && business.client_name) {
      this.clientNameTarget.value = business.client_name
    }
    if (this.hasClientEmailTarget && business.email) {
      this.clientEmailTarget.value = business.email
    }
    if (this.hasClientPhoneTarget && business.phone) {
      this.clientPhoneTarget.value = business.phone
    }
    if (this.hasTitleTarget && business.name) {
      this.titleTarget.value = `Meeting with ${business.name}`
    }
  }

  setDuration(event) {
    event.preventDefault()
    if (this.hasDurationTarget) {
      this.durationTarget.value = event.currentTarget.dataset.duration
    }
  }
}
