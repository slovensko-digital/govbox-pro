import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 0 },
  };

  connect() {
    if (this.timeoutValue > 0) {
      setTimeout(() => {
        this.dismiss();
      }, this.timeoutValue);
    }
  }

  dismiss() {
    this.element.remove();
  }
}
