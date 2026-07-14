import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "businessSelect", "clientName", "clientEmail", "clientPhone", "title", "duration", "date", "slotsFrame" ]
  static values = {
    businesses: Object,
    slotsUrl: String,
    excludingId: String
  }

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
      this.reloadSlots()
    }
  }

  reloadSlots() {
    if (!this.hasSlotsFrameTarget || !this.hasSlotsUrlValue) return

    const url = new URL(this.slotsUrlValue, window.location.origin)
    if (this.hasDateTarget && this.dateTarget.value) {
      url.searchParams.set("date", this.dateTarget.value)
    }
    if (this.hasDurationTarget && this.durationTarget.value) {
      url.searchParams.set("duration_minutes", this.durationTarget.value)
    }
    if (this.excludingIdValue) {
      url.searchParams.set("excluding_id", this.excludingIdValue)
    }

    const slotInput = this.element.querySelector('[data-slot-picker-target="input"]')
    if (slotInput) slotInput.value = ""

    this.slotsFrameTarget.src = url.toString()
  }
}
