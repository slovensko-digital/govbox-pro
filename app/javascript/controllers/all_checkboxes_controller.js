import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.update();
  }

  toggle(event) {
    const form = document.getElementById("thread_checkboxes_form");

    form.querySelectorAll("input").forEach((input) => {
      input.checked = event.target.checked;
    });
    form.requestSubmit();
  }

  update() {
    const form = document.getElementById("thread_checkboxes_form");
    const checkbox_all = document.getElementById("checkbox-all");

    var target_state;

    form.querySelectorAll("input#message_thread_ids_").forEach((input) => {
      if (target_state != false) {
        if (input.checked) {
          target_state = true;
        } else {
          target_state = false;
        }
      }
    });
    checkbox_all.checked = target_state;
  }
}
