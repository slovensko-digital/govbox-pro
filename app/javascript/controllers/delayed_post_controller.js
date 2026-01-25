import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class DelayedPostController extends Controller {
  static values = {
    url: String,
    timeout: { type: Number, default: 1000 }
  }

  connect() {
    this.timeoutId = setTimeout(() => {
      this.doPost()
    }, this.timeoutValue)
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  async doPost() {
    try {
      await post(this.urlValue, {
        responseKind: "turbo-stream"
      })
    } catch (error) {
      console.error('Error making delayed POST request:', error)
    }
  }
}