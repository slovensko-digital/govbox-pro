import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["hr-container", "hr"]

  initialize() {
    new ResizeObserver(() => {
      const hrContainerTagOffset = this.hrTarget.offsetLeft
      const firstNonHrContainerTagOffset = this['hr-containerTarget'].nextElementSibling.offsetLeft

      this.hrTarget.classList[firstNonHrContainerTagOffset < hrContainerTagOffset ? 'add' : 'remove']('opacity-0')
    }).observe(document.body);
  }
}
