import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class MarkReadController extends Controller {
  static values = {
    url: String
  }

  connect() {
    post(this.urlValue, { responseKind: "turbo-stream" }).catch((error) => {
      console.error('Error marking thread as read:', error)
    })
  }
}