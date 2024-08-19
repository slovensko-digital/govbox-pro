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

  bulkSubmit = async () => {
    const submitButtonId = this.data.get("submitButtonId");
    const submitFormId = this.data.get("submitFormId");

    const signaturesInfo = await this.getPendingRequestedSignaturesInfo();

    if (signaturesInfo['pending_requested_signatures'] === true) {
      if (confirm("Správy ešte neboli podpísané všetkými podpismi. Naozaj chcete odoslať správy aj bez nich?")) {
        const submitter = document.getElementById(submitButtonId);
        document.getElementById(submitFormId).requestSubmit(submitter);
      }
    }
    else {
      if (confirm("Naozaj chcete odoslať rozpracované správy v označených vláknach?")) {
        const submitter = document.getElementById(submitButtonId)
        document.getElementById(submitFormId).requestSubmit(submitter);
      }
    }
  }

  submitDrafts = async () => {
    const threadIds = this.data.get("threadIds");
    const authenticityToken = this.data.get("authenticityToken");

    return await post(`/message_threads/bulk/message_drafts/submit`,{
      headers: {'Content-Type': 'application/json'},
      responseKind: "turbo-stream",
      body: JSON.stringify({
        message_thread_ids: JSON.parse(threadIds),
        authenticity_token: authenticityToken
      })
    })
  }

  getPendingRequestedSignaturesInfo = async () => {
    const threadIds = this.data.get("threadIds");
    const authenticityToken = this.data.get("authenticityToken");

    const response = await fetch(`/message_threads/bulk/message_drafts/pending_requested_signatures`,{
      method: "POST",
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        message_thread_ids: JSON.parse(threadIds),
        authenticity_token: authenticityToken
      })
    })

    if (response.ok) {
      return await response.json()
    }

    throw new Error('getPendingRequestedSignaturesInfo failed')
  }
}
