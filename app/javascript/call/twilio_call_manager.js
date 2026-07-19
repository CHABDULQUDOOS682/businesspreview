const TOKEN_REFRESH_MS = 50 * 60 * 1000

let device = null
let activeCall = null
let initPromise = null
let tokenRefreshTimer = null
let state = {
  status: "idle",
  phoneNumber: null,
  label: null,
  error: null,
  inCall: false
}

const listeners = new Set()

function emit() {
  listeners.forEach((listener) => listener({ ...state }))
}

function setState(patch) {
  state = { ...state, ...patch }
  emit()
}

function formatError(error) {
  const code = error?.code || error?.twilioError?.code || "Unknown"
  const message = error?.message || error?.twilioError?.message || "Unknown error"
  return `${code} - ${message}`
}

function scheduleTokenRefresh() {
  clearTimeout(tokenRefreshTimer)
  tokenRefreshTimer = setTimeout(() => {
    refreshToken().catch((error) => {
      console.error("Twilio token refresh failed:", error)
    })
  }, TOKEN_REFRESH_MS)
}

async function fetchToken() {
  const response = await fetch("/twilio/token", { credentials: "same-origin" })
  if (!response.ok) throw new Error("Failed to fetch token")

  const data = await response.json()
  if (data.error) throw new Error(data.error)

  return data.token
}

async function refreshToken() {
  if (!device) return

  const token = await fetchToken()
  device.updateToken(token)
  scheduleTokenRefresh()
}

async function ensureDevice() {
  if (device) return device
  if (initPromise) return initPromise

  initPromise = (async () => {
    if (!window.isSecureContext && window.location.hostname !== "localhost") {
      throw new Error("Browser calling requires HTTPS")
    }

    if (typeof Twilio === "undefined") {
      throw new Error("Twilio Voice SDK is not loaded")
    }

    setState({ status: "initializing", error: null })

    const token = await fetchToken()

    device = new Twilio.Device(token, {
      codecPreferences: ["opus", "pcmu"],
      fakeLocalAudio: true,
      enableIceRestart: true
    })

    device.on("registered", () => {
      setState({ status: "ready", error: null })
      scheduleTokenRefresh()
    })

    device.on("unregistered", () => {
      setState({ status: "disconnected", inCall: false, error: null })
    })

    device.on("error", (error) => {
      setState({ status: "error", error: formatError(error), inCall: false })
      console.error("Twilio Device Error:", error)
    })

    device.on("connect", (call) => {
      activeCall = call
      setState({ status: "in_call", inCall: true, error: null })
    })

    device.on("disconnect", () => {
      activeCall = null
      const endedLabel = state.label
      setState({
        status: "ended",
        inCall: false,
        phoneNumber: null,
        label: endedLabel,
        error: null
      })

      setTimeout(() => {
        if (state.status === "ended") {
          setState({ status: "ready", label: null, error: null })
        }
      }, 3000)
    })

    await device.register()
    return device
  })().catch((error) => {
    initPromise = null
    setState({ status: "error", error: error.message })
    throw error
  })

  return initPromise
}

export function subscribe(listener) {
  listeners.add(listener)
  listener({ ...state })
  return () => listeners.delete(listener)
}

export function getCallState() {
  return { ...state }
}

export async function startCall({ phoneNumber, label = null, businessId = null }) {
  if (!phoneNumber) return

  setState({
    status: "connecting",
    phoneNumber,
    label: label || phoneNumber,
    error: null,
    inCall: false
  })

  try {
    const twilioDevice = await ensureDevice()
    setState({ status: "connecting" })

    const params = { To: phoneNumber }
    if (businessId) params.BusinessId = String(businessId)

    const metaUserId = document.querySelector('meta[name="current-user-id"]')?.content
    if (metaUserId) params.UserId = metaUserId

    activeCall = await twilioDevice.connect({ params })
  } catch (error) {
    setState({
      status: "error",
      error: formatError(error),
      inCall: false
    })
    console.error("Twilio Connect Error:", error)
  }
}

export function hangup() {
  if (device) device.disconnectAll()
  activeCall = null
  setState({
    status: "ended",
    inCall: false,
    phoneNumber: null,
    error: null
  })

  setTimeout(() => {
    if (state.status === "ended") {
      setState({ status: "ready", label: null, error: null })
    }
  }, 2000)
}

export function dismiss() {
  if (state.inCall) {
    hangup()
    return
  }

  setState({
    status: "ready",
    phoneNumber: null,
    label: null,
    error: null,
    inCall: false
  })
}

export async function warmUp() {
  try {
    await ensureDevice()
  } catch (error) {
    console.error("Twilio warm up failed:", error)
  }
}
