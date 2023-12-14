import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["separator-container", "separator"]

  initialize() {
    new ResizeObserver(() => {
      const hrContainerTagOffset = this.separatorTarget.offsetLeft
      const firstNonHrContainerTagOffset = this["separator-containerTarget"].nextElementSibling.offsetLeft

      this.separatorTarget.classList[firstNonHrContainerTagOffset < hrContainerTagOffset ? "add" : "remove"]("opacity-0")
    }).observe(document.body)
  }
}
