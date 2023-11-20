import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.innerHTML = this.element.innerHTML.replace(/_/g, '_<wbr/>');
  }
}
