import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  remove() {
    this.element.parentElement.removeAttribute("src")
    this.element.parentElement.removeAttribute("complete")
    this.element.remove()
  }
}
