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
    if (this.hasCallButtonTarget) this.callButtonTarget.disabled = true
    this.toggleButtons(false)
    this.setupDevice()
  }

  async setupDevice() {
    try {
      if (!window.isSecureContext && window.location.hostname !== "localhost") {
        this.updateStatus("Error: Browser calling requires HTTPS")
        return
      }

      const response = await fetch("/twilio/token")
      if (!response.ok) {
        this.updateStatus("Error: Failed to fetch token")
        return
      }
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

      this.device.on("registered", () => {
        this.updateStatus("Ready")
        if (this.hasCallButtonTarget) this.callButtonTarget.disabled = false
      })

      this.device.on("unregistered", () => {
        this.updateStatus("Disconnected")
        if (this.hasCallButtonTarget) this.callButtonTarget.disabled = true
        this.toggleButtons(false)
      })

      this.device.on("error", (error) => {
        const code = error?.code || error?.twilioError?.code || "Unknown"
        const message = error?.message || error?.twilioError?.message || "Unknown error"
        const errorMsg = `Error: ${code} - ${message}`
        this.updateStatus(errorMsg)
        console.error("Twilio Device Error:", error)
        this.toggleButtons(false)
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

      try {
        await this.device.register()
      } catch (error) {
        const code = error?.code || error?.twilioError?.code || "Unknown"
        const message = error?.message || error?.twilioError?.message || "Unknown error"
        this.updateStatus(`Error: ${code} - ${message}`)
        console.error("Twilio Register Error:", error)
      }
    } catch (error) {
      this.updateStatus("Failed to init")
      console.error("Setup Error:", error)
    }
  }

  async makeCall() {
    if (!this.device) return

    this.updateStatus("Connecting...")
    this.toggleButtons(true)
    try {
      this.activeCall = await this.device.connect({
        params: { To: this.phoneNumberValue }
      })
    } catch (error) {
      const code = error?.code || error?.twilioError?.code || "Unknown"
      const message = error?.message || error?.twilioError?.message || "Unknown error"
      this.updateStatus(`Error: ${code} - ${message}`)
      console.error("Twilio Connect Error:", error)
      this.toggleButtons(false)
    }
  }

  hangup() {
    if (this.device) {
      this.device.disconnectAll()
    }
    this.updateStatus("Call Ended")
    setTimeout(() => this.updateStatus("Ready"), 3000)
    this.toggleButtons(false)
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
    if (this.hasCallButtonTarget) {
      this.callButtonTarget.style.display = isCallActive ? "none" : "inline-flex"
    }
    if (this.hasHangupButtonTarget) {
      this.hangupButtonTarget.style.display = isCallActive ? "inline-flex" : "none"
    }
  }
}
