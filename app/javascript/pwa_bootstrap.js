// PWA install bootstrap.
// Download app uses a real form POST (shows in Rails logs). JS intercepts to also
// open Chrome's install prompt when beforeinstallprompt is available.
(() => {
  if (typeof window === "undefined") return

  window.__pwaDeferredPrompt = window.__pwaDeferredPrompt || null

  const swUrl = "/service-worker.js"

  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault()
    window.__pwaDeferredPrompt = event
    console.info("[PWA] beforeinstallprompt ready")
  })

  window.addEventListener("appinstalled", () => {
    window.__pwaDeferredPrompt = null
    console.info("[PWA] appinstalled")
  })

  async function registerServiceWorker() {
    if (!("serviceWorker" in navigator)) return false

    try {
      const registrations = await navigator.serviceWorker.getRegistrations()
      await Promise.all(
        registrations.map((registration) => {
          const script =
            registration.active?.scriptURL ||
            registration.installing?.scriptURL ||
            registration.waiting?.scriptURL ||
            ""
          if (script.includes("/admin/service-worker.js")) {
            return registration.unregister()
          }
          return Promise.resolve()
        })
      )

      await navigator.serviceWorker.register(swUrl, { scope: "/" })
      await navigator.serviceWorker.ready
      return true
    } catch (error) {
      console.warn("[PWA] service worker registration failed", error)
      return false
    }
  }

  void registerServiceWorker()

  async function tryNativeInstall() {
    const promptEvent = window.__pwaDeferredPrompt
    if (!promptEvent) {
      console.warn("[PWA] no beforeinstallprompt — native install dialog unavailable")
      return false
    }

    try {
      promptEvent.prompt()
      const choice = await promptEvent.userChoice
      console.info("[PWA] userChoice", choice)
      window.__pwaDeferredPrompt = null
      return choice?.outcome === "accepted"
    } catch (error) {
      console.warn("[PWA] prompt() failed", error)
      return false
    }
  }

  window.DevDeBizzPwa = {
    // Called from the Download app form onsubmit.
    // Returns false to cancel the full-page POST after we handle it via fetch + prompt.
    handleFormSubmit(event) {
      event.preventDefault()
      const form = event.target
      void this.installFromForm(form)
      return false
    },

    async installFromForm(form) {
      console.info("[PWA] Download app clicked")

      const swReady = await registerServiceWorker()
      const hasPrompt = Boolean(window.__pwaDeferredPrompt)
      const standalone =
        window.matchMedia("(display-mode: standalone)").matches ||
        window.navigator.standalone === true

      const formData = new FormData(form)
      formData.set("has_prompt", String(hasPrompt))
      formData.set("service_worker", String(swReady))
      formData.set("standalone", String(standalone))

      try {
        const response = await fetch(form.action, {
          method: "POST",
          headers: {
            "Accept": "application/json",
            "X-Requested-With": "XMLHttpRequest"
          },
          credentials: "same-origin",
          body: formData
        })
        console.info("[PWA] install_click status", response.status)
      } catch (error) {
        console.warn("[PWA] install_click request failed", error)
      }

      if (standalone) return

      await tryNativeInstall()
    }
  }
})()
