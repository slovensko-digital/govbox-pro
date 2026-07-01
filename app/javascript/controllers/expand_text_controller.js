import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const content = this.element.querySelector("[data-expand-content]")
    const indicator = this.element.querySelector("[data-expand-indicator]")
    if (!content || !indicator) return

    setTimeout(() => {
      if (content.scrollWidth <= content.clientWidth) {
        indicator.hidden = true
        this.element.classList.remove("cursor-pointer", "select-none")
      }
    }, 0)
  }

  toggle() {
    const content = this.element.querySelector("[data-expand-content]")
    const indicator = this.element.querySelector("[data-expand-indicator]")
    if (!content || !indicator || indicator.hidden) return

    content.classList.toggle("truncate")
    content.classList.toggle("whitespace-normal")
    indicator.textContent = content.classList.contains("truncate") ? "▾" : "▴"
  }
}
