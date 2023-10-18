import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [ "form" ]

  send() {
    this.formTarget.requestSubmit();
  }
}
