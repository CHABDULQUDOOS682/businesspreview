import { Controller } from "@hotwired/stimulus"
import { startCall } from "call/twilio_call_manager"

export default class extends Controller {
  static values = {
    phoneNumber: String,
    label: String,
    businessId: Number
  }

  call(event) {
    event.preventDefault()

    if (!this.phoneNumberValue) return

    startCall({
      phoneNumber: this.phoneNumberValue,
      label: this.hasLabelValue ? this.labelValue : this.phoneNumberValue,
      businessId: this.hasBusinessIdValue ? this.businessIdValue : null
    })
  }
}
