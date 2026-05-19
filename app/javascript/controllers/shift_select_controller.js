import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox"];

  connect() {
    this.lastChecked = null;
  }

  toggle(event) {
    const checkbox = event.currentTarget;

    if (event.shiftKey && this.lastChecked && this.lastChecked !== checkbox) {
      const start = this.checkboxTargets.indexOf(checkbox);
      const end = this.checkboxTargets.indexOf(this.lastChecked);

      const inBetween = this.checkboxTargets.slice(Math.min(start, end), Math.max(start, end) + 1);

      inBetween.forEach(cb => {
        cb.checked = checkbox.checked;
      });
    }

    this.lastChecked = checkbox.checked ? checkbox : null;
  }
}
