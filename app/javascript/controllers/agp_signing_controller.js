import { Controller } from "@hotwired/stimulus"
import { get, post } from "@rails/request.js"

const SYNC_POLL_INTERVAL = 1000
const SYNC_POLL_ATTEMPTS = 60
const sdkLoads = {}

// Embeds the Autogram Portal (AGP) bundle signing iframe. The signing itself, including the calls to the local
// Autogram app, runs inside the iframe: the SDK delegates the loopback network permission to it, so the page must
// not restrict that permission with a Permissions-Policy and its CSP must allow AGP in frame-src.
export default class extends Controller {
  static targets = ["iframe", "syncing", "progress", "failed", "timeout", "error"]
  static values = { agpUrl: String, bundleId: String, statusUrl: String, syncUrl: String }

  connect() {
    this.loadSdk()
      .then(() => this.initIframe())
      .catch((error) => {
        console.error("AGP SDK could not be loaded", error)
        this.show(this.errorTarget)
      })
  }

  disconnect() {
    clearTimeout(this.pollTimeout)
    this.agpInstance?.destroy()
    this.agpInstance = null
  }

  loadSdk() {
    const url = `${this.agpUrlValue}/sdk.js`

    sdkLoads[url] ||= new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = url
      script.nonce = document.querySelector("meta[name='csp-nonce']")?.content
      script.onload = resolve
      script.onerror = () => {
        delete sdkLoads[url]
        reject(new Error(`Failed to load ${url}`))
      }
      document.head.appendChild(script)
    })

    return sdkLoads[url]
  }

  initIframe() {
    if (!this.element.isConnected || this.agpInstance) return

    this.agpInstance = window.agp.initBundleIframe(this.bundleIdValue, {
      mode: "iframe",
      previewLevel: "no_onboarding",
      baseUrl: this.agpUrlValue,
      parentElement: this.iframeTarget,
      locale: "sk",
      width: "100%",
      height: "650px",
      onMessage: (event) => this.handleMessage(event)
    })
  }

  handleMessage(event) {
    if (event.status !== "document-signed") return

    // do not wait for the webhook, it may be delayed or not reach GovBox at all
    this.requestSync()

    if (event.close_iframe) this.waitForSync()
  }

  requestSync() {
    post(this.syncUrlValue).catch((error) => console.error("AGP sync request failed", error))
  }

  waitForSync() {
    if (this.waiting) return

    this.waiting = true
    this.pollAttempts = 0
    this.show(this.syncingTarget)
    this.poll()
  }

  async poll() {
    try {
      const response = await get(this.statusUrlValue, { responseKind: "json" })

      if (response.ok) {
        const status = await response.json

        this.progressTarget.textContent = `${status.completed_contracts_count} / ${status.total_contracts_count}`
        if (status.status === "completed") return this.finish()
        if (status.status === "failed") return this.show(this.failedTarget)
      }
    } catch (error) {
      console.error("AGP sync status request failed", error)
    }

    this.pollAttempts += 1
    if (this.pollAttempts >= SYNC_POLL_ATTEMPTS) return this.show(this.timeoutTarget)
    if (this.pollAttempts % 10 === 0) this.requestSync()

    this.pollTimeout = setTimeout(() => this.poll(), SYNC_POLL_INTERVAL)
  }

  finish() {
    Turbo.visit(window.location.href, { action: "replace" })
  }

  reload() {
    window.location.reload()
  }

  show(target) {
    [this.iframeTarget, this.syncingTarget, this.failedTarget, this.timeoutTarget, this.errorTarget].forEach((element) => {
      element.classList.toggle("hidden", element !== target)
    })
  }
}
