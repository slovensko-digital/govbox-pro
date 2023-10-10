import { Controller } from "@hotwired/stimulus"
import { post, patch } from '@rails/request.js'

export default class extends Controller {

  async update() {
    const authenticityToken = this.data.get("authenticityToken");
    const messageDraftPath = this.data.get("messageDraftPath");

    await patch(messageDraftPath, {
      body: JSON.stringify({
        authenticity_token: authenticityToken,
        message_title: document.getElementById("message_title").value,
        message_text: document.getElementById("message_text").value
      }),
      responseKind: "turbo-stream"
    })
  }

  uploadAttachments() {
    document.getElementById("attachment_form").requestSubmit();
  }
}
