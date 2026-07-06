import { Controller } from "@hotwired/stimulus"
import { subscribe, hangup, dismiss, getCallState } from "call/twilio_call_manager"

export default class extends Controller {
  static targets = [
    "panel",
    "minimized",
    "label",
    "number",
    "status",
    "hangupButton",
    "dismissButton",
    "pulse"
  ]

  connect() {
    this.minimized = false
    this.unsubscribe = subscribe((state) => this.render(state))
    this.render(getCallState())
  }

  disconnect() {
    if (this.unsubscribe) this.unsubscribe()
  }

  hangup(event) {
    event?.preventDefault()
    hangup()
  }

  dismiss(event) {
    event?.preventDefault()
    dismiss()
    this.minimized = false
  }

  minimize() {
    this.minimized = true
    this.syncVisibility(getCallState())
  }

  expand() {
    this.minimized = false
    this.syncVisibility(getCallState())
  }

  render(state) {
    if (["connecting", "initializing", "in_call"].includes(state.status)) {
      this.minimized = false
    }
    this.updateCopy(state)
    this.syncVisibility(state)
  }

  updateCopy(state) {
    if (this.hasLabelTarget) {
      this.labelTarget.textContent = state.label || "Phone call"
    }

    if (this.hasNumberTarget) {
      this.numberTarget.textContent = state.phoneNumber || ""
      this.numberTarget.classList.toggle("hidden", !state.phoneNumber)
    }

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = this.statusLabel(state)
      this.statusTarget.className = this.statusClass(state)
    }

    if (this.hasHangupButtonTarget) {
      const showHangup = state.inCall || state.status === "connecting"
      this.hangupButtonTarget.classList.toggle("hidden", !showHangup)
    }

    if (this.hasDismissButtonTarget) {
      const showDismiss = !state.inCall && ["error", "ended"].includes(state.status)
      this.dismissButtonTarget.classList.toggle("hidden", !showDismiss)
    }

    if (this.hasPulseTarget) {
      this.pulseTarget.classList.toggle("hidden", !state.inCall)
    }
  }

  syncVisibility(state) {
    const active = this.isWidgetActive(state)

    if (this.hasPanelTarget) {
      this.panelTarget.classList.toggle("hidden", !active || this.minimized)
    }

    if (this.hasMinimizedTarget) {
      this.minimizedTarget.classList.toggle("hidden", !active || !this.minimized)
    }
  }

  isWidgetActive(state) {
    return !["idle", "ready"].includes(state.status) || state.inCall
  }

  statusLabel(state) {
    switch (state.status) {
      case "initializing":
        return "Initializing phone..."
      case "connecting":
        return "Connecting..."
      case "in_call":
        return "In call"
      case "ended":
        return "Call ended"
      case "error":
        return state.error || "Call error"
      case "disconnected":
        return "Disconnected"
      default:
        return "Ready"
    }
  }

  statusClass(state) {
    const base = "text-xs font-medium "
    if (state.status === "in_call") return `${base} text-blue-600`
    if (state.status === "error") return `${base} text-red-600`
    if (state.status === "ended") return `${base} text-slate-500`
    if (state.status === "connecting" || state.status === "initializing") {
      return `${base} text-amber-600`
    }
    return `${base} text-green-600`
  }
}
