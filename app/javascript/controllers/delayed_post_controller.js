import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class DelayedPostController extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.doPost()
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