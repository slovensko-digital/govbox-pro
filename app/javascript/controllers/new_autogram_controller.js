import { Controller } from "@hotwired/stimulus"
import { isAutogramRunning, startBatch, signMessageObject, endBatch } from "../autogram"

export default class extends Controller {
  static targets = ["appNotRunning", "signingInProgress", "doneOk", "doneError", "openAutogramApp"]

  connect() {
    this.signAll()
  }

  async signAll() {
    const { files, token } = this.getInputData()
    if (!await this.assertAutogramIsRunning()) {
      return
    }

    try {
      const usingBatch = files.length > 1
      const batchId = usingBatch ? await startBatch(files.length) : null

      for await (const file of files) {
        await signMessageObject(file.path, batchId, token)
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
    }
  }

  getInputData() {
    const authenticityToken = this.data.get("authenticityToken");
    const files = JSON.parse(this.data.get("filesToBeSigned"));

    if (!!authenticityToken && files.length) {
      return {
        token: authenticityToken,
        files: files,
      }
    }

    throw new Error('missing input data')
  }

  async assertAutogramIsRunning() {
    this.signingInProgressTarget.classList.add("hidden")
    this.appNotRunningTarget.classList.add("hidden")

    if (!await isAutogramRunning()) {
      this.openAutogramAppTarget.click()

      this.signingInProgressTarget.classList.add("hidden")
      this.appNotRunningTarget.classList.remove("hidden")
      return false
    }

    this.appNotRunningTarget.classList.add("hidden")
    this.signingInProgressTarget.classList.remove("hidden")

    return true
  }
}
