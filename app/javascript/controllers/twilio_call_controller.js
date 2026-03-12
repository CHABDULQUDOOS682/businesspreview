import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "callButton", "hangupButton", "numberDisplay", "dialerModal"]
  static values = {
    phoneNumber: String
  }

  connect() {
    this.device = null
    this.activeCall = null
    console.log("Twilio Call Controller Connected for:", this.phoneNumberValue)
    this.setupDevice()
  }

  async setupDevice() {
    try {
      const response = await fetch("/twilio/token")
      const data = await response.json()
      
      if (data.error) {
        this.updateStatus("Config Error: Check .env")
        console.error(data.error)
        return
      }

      this.device = new Twilio.Device(data.token, {
        codecPreferences: ["opus", "pcmu"],
        fakeLocalAudio: true,
        enableIceRestart: true,
      })

      this.device.on("ready", () => {
        this.updateStatus("Ready")
        this.callButtonTarget.disabled = false
      })

      this.device.on("error", (error) => {
        const errorMsg = `Error: ${error.code} - ${error.message}`
        this.updateStatus(errorMsg)
        console.error("Twilio Device Error:", error)
      })

      this.device.on("connect", (call) => {
        this.updateStatus("In Call")
        this.activeCall = call
        this.toggleButtons(true)
      })

      this.device.on("disconnect", () => {
        this.updateStatus("Call Ended")
        this.activeCall = null
        this.toggleButtons(false)
        setTimeout(() => this.updateStatus("Ready"), 3000)
      })

    } catch (error) {
      this.updateStatus("Failed to init")
      console.error("Setup Error:", error)
    }
  }

  makeCall() {
    if (!this.device) return

    this.updateStatus("Connecting...")
    this.activeCall = this.device.connect({
      params: { To: this.phoneNumberValue }
    })
  }

  hangup() {
    if (this.device) {
      this.device.disconnectAll()
    }
  }

  updateStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      
      // Update status colors
      this.statusTarget.classList.remove("text-green-600", "text-red-600", "text-blue-600", "text-gray-500")
      if (message === "Ready") this.statusTarget.classList.add("text-green-600")
      else if (message.includes("Error")) this.statusTarget.classList.add("text-red-600")
      else if (message === "In Call") this.statusTarget.classList.add("text-blue-600")
      else this.statusTarget.classList.add("text-gray-500")
    }
  }

  toggleButtons(isCallActive) {
    if (this.hasCallButtonTarget) this.callButtonTarget.classList.toggle("hidden", isCallActive)
    if (this.hasHangupButtonTarget) this.hangupButtonTarget.classList.toggle("hidden", !isCallActive)
  }
}
