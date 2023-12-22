import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    document.body.style.overflow = "hidden"
  }

  remove() {
    document.body.style.overflow = ""
    this.element.parentElement.removeAttribute("src")
    this.element.parentElement.removeAttribute("complete")
    this.element.remove()
  }
}
