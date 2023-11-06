import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    indeterminate: String,
    checked: String
  }

  connect() {
    if (this.element.checked && this.element.value === this.indeterminateValue) {
      this.element.indeterminate = true
    }
  }

  nextValue(event) {
    if (event.target.checked === false && event.target.value === this.indeterminateValue) {
      event.target.checked = true
      event.target.value = this.checkedValue
    } else if (event.target.checked === false && event.target.value === this.checkedValue) {
      event.target.value = this.indeterminateValue
    } else {
      this.element.indeterminate = true
    }
  }
}
