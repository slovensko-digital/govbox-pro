import { Controller } from "@hotwired/stimulus"
import { get, patch } from '@rails/request.js'

export default class extends Controller {
  connect() {
    const newDraftsElement = document.getElementById("new_drafts")
    newDraftsElement.addEventListener("DOMNodeInserted", this.showLastMessageDraft);
  }

  async changed() {
    console.log("Here!");
    debugger;
  }

  async loadRecipientsServices() {
    debugger;

    const recipientServicesPath = this.data.get("recipientServicesPath");
    const recipientUri = document.getElementById("recipient").value;
    await get(recipientServicesPath, {
      query: {
        institution_uri: recipientUri
      }
    });
  }

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
      })
    })
  }

  uploadAttachments() {
    const attachmentsFormId = this.data.get("attachmentsFormId");
    document.getElementById(attachmentsFormId).requestSubmit();
  }

  showLastMessageDraft() {
    const messageDraftsTexts = document.querySelectorAll('textarea[id^="text_message_draft_"]');
    const length = messageDraftsTexts.length;
    if (messageDraftsTexts.length > 1) {
      messageDraftsTexts[length - 2].setAttribute('autofocus', false);
    }
    messageDraftsTexts[length - 1].focus();

    const drafts = document.querySelectorAll(".draft");
    const lastDraft = drafts[drafts.length - 1];
    lastDraft.scrollIntoView();
  }
}
