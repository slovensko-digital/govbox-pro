import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  submit({ params }) {
    const form = this.element.form;
    const submitter = params.submitter && form.querySelector(`#${params.submitter}`);

    form.requestSubmit(submitter || undefined);

    if (params.disable) this.element.disabled = true;
  }
}
