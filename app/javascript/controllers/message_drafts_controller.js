import { Controller } from "@hotwired/stimulus"
import { get, post } from '@rails/request.js'

export default class extends Controller {
  connect() {
    const newDraftsElement = document.getElementById("new_drafts")
    if (newDraftsElement != null) {
      newDraftsElement.addEventListener("DOMNodeInserted", this.showLastMessageDraft);
    }
  }

  async loadTemplateRecipients() {
    const messageTemplateId = document.getElementById("message_template_id").value;
    const templateRecipientsPath = `/message_templates/${messageTemplateId}/recipients_list`;
    await get(templateRecipientsPath, { responseKind: "turbo-stream" })
  }

  async create() {
    const formId = this.data.get("formId");
    document.getElementById(formId).requestSubmit();
  }

  async update() {
    const messageDraftBodyFormId = this.data.get("messageDraftBodyFormId");
    document.getElementById(messageDraftBodyFormId).requestSubmit();
  }

  uploadAttachments() {
    const attachmentsFormId = this.data.get("attachmentsFormId");
    document.getElementById(attachmentsFormId).requestSubmit();
  }

  showLastMessageDraft() {
    // TODO get rid of message_draft[Text] constant
    const messageDraftsTexts = document.querySelectorAll('textarea[name^="message_draft[Text]"]');
    const length = messageDraftsTexts.length;
    if (messageDraftsTexts.length > 1) {
      messageDraftsTexts[length - 2].setAttribute("autofocus", false);
    }
    messageDraftsTexts[length - 1].focus();

    const drafts = document.querySelectorAll(".draft");
    const lastDraft = drafts[drafts.length - 1];
    lastDraft.scrollIntoView();
  }
}
