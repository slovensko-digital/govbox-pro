import { Controller } from "@hotwired/stimulus"
import { post, patch } from '@rails/request.js'

export default class extends Controller {

  async update() {
    const authenticityToken = this.data.get("authenticityToken");
    const messageDraftPath = this.data.get("messageDraftPath");
    const messageDraftTitleId = this.data.get("titleId");
    const messageDraftTextId = this.data.get("textId");

    await patch(messageDraftPath, {
      body: JSON.stringify({
        authenticity_token: authenticityToken,
        message_title: document.getElementById(messageDraftTitleId).value,
        message_text: document.getElementById(messageDraftTextId).value
      }),
      responseKind: "turbo-stream"
    })
  }

  uploadAttachments() {
    const attachmentsFormId = this.data.get("attachmentsFormId");

    document.getElementById(attachmentsFormId).requestSubmit();
  }
}
