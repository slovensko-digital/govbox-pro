import { Controller } from "@hotwired/stimulus"
import { isAutogramRunning, startBatch, signMessageObject, endBatch } from "../autogram"

export default class extends Controller {
  static targets = ["appNotRunning", "waitingForAutogram", "signingInProgress", "signingProgressText", "macosHint", "doneOk", "doneError", "openAutogramApp"]

  connect() {
    this.pollIntervalMs = 1000
    this.pollTimeoutMs = 30000
    this.pollIntervalId = null
    this.pollTimeoutId = null
    this.pollingInFlight = false
    this.isSigning = false

    this.configureAutogramLaunchUrl()
    this.signAll()
  }

  disconnect() {
    this.stopAutogramPolling()
  }

  async signAll() {
    if (this.isSigning) {
      return
    }

    this.isSigning = true

    let files = []
    let token = null
    let signatureSettings = null
    let batchId = null

    try {
      ({ files, token, signatureSettings } = this.getInputData())

      if (!await this.ensureAutogramIsRunning()) {
        return
      }

      this.showSigningInProgressState()

      if (files.length > 1) {
        batchId = await startBatch(files.length)
        if (batchId == null) {
          console.error('Batch ID is null');
          this.doneErrorTarget.click()
          return;
        }
      }

      for (const [index, file] of files.entries()) {
        this.updateSigningProgress(index + 1, files.length)
        await signMessageObject(file.path, batchId, token, signatureSettings)
      }

      this.doneOkTarget.click()
    } catch (error) {
      console.log('error during signing', error)

      try {
        if (batchId !== null) {
          await endBatch(batchId)
        }
      }
      catch {
        // delete batch should be idempotent
      }

      this.doneErrorTarget.click()
    } finally {
      this.isSigning = false
    }
  }

  getInputData() {
    const authenticityToken = this.data.get("authenticityToken");
    const files = JSON.parse(this.data.get("filesToBeSigned"));
    const signatureSettings = JSON.parse(this.data.get("signatureSettings"));

    if (!!authenticityToken && files.length) {
      return {
        token: authenticityToken,
        files: files,
        signatureSettings: signatureSettings
      }
    }

    throw new Error('missing input data')
  }

  async ensureAutogramIsRunning() {
    this.showWaitingForAutogramState()

    if (await isAutogramRunning()) {
      return true
    }

    this.launchAutogramApp()
    this.showWaitingForAutogramState()

    const isRunning = await this.waitForAutogramStart()

    if (!isRunning) {
      this.showAppNotRunningState()
      return false
    }

    return true
  }

  async waitForAutogramStart() {
    let settled = false

    return await new Promise((resolve) => {
      const checkRunning = async () => {
        if (settled || this.pollingInFlight) {
          return
        }

        this.pollingInFlight = true

        try {
          if (await isAutogramRunning()) {
            settled = true
            this.stopAutogramPolling()
            resolve(true)
          }
        } finally {
          this.pollingInFlight = false
        }
      }

      this.pollTimeoutId = setTimeout(async () => {
        if (settled) {
          return
        }

        // Final readiness check to avoid a false negative near timeout boundary.
        try {
          if (await isAutogramRunning()) {
            settled = true
            this.stopAutogramPolling()
            resolve(true)
            return
          }
        } catch {
          // ignore and fall through to unresolved state
        }

        settled = true
        this.stopAutogramPolling()
        resolve(false)
      }, this.pollTimeoutMs)

      checkRunning()
      this.pollIntervalId = setInterval(checkRunning, this.pollIntervalMs)
    })
  }

  stopAutogramPolling() {
    if (this.pollIntervalId !== null) {
      clearInterval(this.pollIntervalId)
      this.pollIntervalId = null
    }

    if (this.pollTimeoutId !== null) {
      clearTimeout(this.pollTimeoutId)
      this.pollTimeoutId = null
    }
  }

  showWaitingForAutogramState() {
    this.setModalHeader(this.data.get("modalHeaderSigning"))
    this.appNotRunningTarget.classList.add("hidden")
    this.signingInProgressTarget.classList.add("hidden")
    this.waitingForAutogramTarget.classList.remove("hidden")
  }

  showSigningInProgressState() {
    this.setModalHeader(this.data.get("modalHeaderSigning"))
    this.appNotRunningTarget.classList.add("hidden")
    this.waitingForAutogramTarget.classList.add("hidden")
    this.signingInProgressTarget.classList.remove("hidden")
  }

  showAppNotRunningState() {
    this.setModalHeader(this.data.get("modalHeaderAppNotRunning"))
    this.waitingForAutogramTarget.classList.add("hidden")
    this.signingInProgressTarget.classList.add("hidden")
    this.appNotRunningTarget.classList.remove("hidden")

    if (/Mac|iPhone|iPad/.test(navigator.platform) || /Macintosh/.test(navigator.userAgent)) {
      this.macosHintTarget.classList.remove("hidden")
    }
  }

  updateSigningProgress(current, total) {
    this.showSigningInProgressState()

    const progressTemplate = this.data.get("signingProgressTemplate")
    const progressText = progressTemplate
      .replace("%{current}", current)
      .replace("%{total}", total)

    this.signingProgressTextTarget.textContent = progressText
  }

  cancel() {
    history.back()
  }

  setModalHeader(text) {
    if (!text) {
      return
    }

    const modalTitle = this.element.closest("[role='dialog']")?.querySelector("#modal-title")
    if (modalTitle) {
      modalTitle.textContent = text
    }
  }

  configureAutogramLaunchUrl() {
    const launchUrl = this.autogramLaunchUrl()
    this.openAutogramAppTarget.setAttribute("href", launchUrl)
  }

  launchAutogramApp() {
    const launchUrl = this.autogramLaunchUrl()
    this.openAutogramAppTarget.setAttribute("href", launchUrl)

    try {
      window.location.assign(launchUrl)
    } catch {
      // Fallback for browsers that may block assign for custom protocols in specific contexts.
      this.openAutogramAppTarget.click()
    }
  }

  autogramLaunchUrl() {
    return this.isSafariOnMacOS() ? "autogram://go?protocol=https" : "autogram://go"
  }

  isSafariOnMacOS() {
    const isMacOS = /Macintosh|MacIntel|MacPPC|Mac68K/.test(navigator.platform)
    const isSafari = /Safari/.test(navigator.userAgent) && !/Chrome|Chromium|CriOS|Edg|OPR|Firefox/.test(navigator.userAgent)

    return isMacOS && isSafari
  }
}
