import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggle(event) {
    const form = document.getElementById("thread_checkboxes_form");

    form.querySelectorAll("input").forEach((input) => {
      input.checked = event.target.checked;
    });
  }
}
