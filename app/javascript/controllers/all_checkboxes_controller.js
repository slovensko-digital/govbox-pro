import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "checkbox", "refresh"];
  checkboxTargetConnected() {
    this.update();
  }

  refreshTargetConnected() {
    this.update();
  }

  toggle(event) {
    this.formTarget.querySelectorAll("input").forEach((input) => {
      input.checked = event.target.checked;
    });
    this.formTarget.requestSubmit();
  }

  update() {
    var target_state;

    this.formTarget.querySelectorAll('input[type="checkbox"]').forEach((input) => {
      if (input.checked && !target_state) target_state = "true";
      else if (input.checked && target_state == "false") target_state = "indeterminate";
      else if (!input.checked && !target_state) target_state = "false";
      else if (!input.checked && target_state == "true") target_state = "indeterminate";
    });

    if (!target_state || target_state == "false") this.checkboxTarget.checked = false;
    else if (target_state == "true") this.checkboxTarget.checked = true;
    else this.checkboxTarget.indeterminate = true;
  }
}
