import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topButton", "bottomButton"]

  connect() {
    this.scrollContainer = this.resolveScrollContainer()
    this.scrollElement = this.scrollContainer === window ? document.documentElement : this.scrollContainer

    this.scrollContainer.addEventListener("scroll", this.updateVisibility, { passive: true })
    window.addEventListener("resize", this.updateVisibility)

    this.resizeObserver = new ResizeObserver(this.updateVisibility)
    this.resizeObserver.observe(this.scrollElement)

    this.updateVisibility()
    requestAnimationFrame(this.updateVisibility)
  }

  disconnect() {
    this.scrollContainer.removeEventListener("scroll", this.updateVisibility)
    window.removeEventListener("resize", this.updateVisibility)
    this.resizeObserver?.disconnect()
  }

  scrollToTop() {
    this.scrollContainer.scrollTo({ top: 0, behavior: "smooth" })
  }

  scrollToBottom() {
    this.scrollContainer.scrollTo({ top: this.scrollElement.scrollHeight, behavior: "smooth" })
  }

  updateVisibility = () => {
    const { scrollTop, scrollHeight, clientHeight } = this.scrollElement
    const totalScrollable = scrollHeight - clientHeight

    let showTop = false, showBottom = false

    if (totalScrollable >= 100) {
      const isCloserToBottom = scrollTop > (totalScrollable / 2)
      const distanceFromBottom = totalScrollable - scrollTop

      showTop = isCloserToBottom && distanceFromBottom > 150
      showBottom = !isCloserToBottom && scrollTop > 150
    }

    this.topButtonTargets.forEach(b => b.toggleAttribute("data-visible", showTop))
    this.bottomButtonTargets.forEach(b => b.toggleAttribute("data-visible", showBottom))
  }

  resolveScrollContainer() {
    let current = this.element.parentElement
    while (current) {
      const { overflowY } = window.getComputedStyle(current)
      if (["auto", "scroll", "overlay"].includes(overflowY) && current.scrollHeight > current.clientHeight) {
        return current
      }
      current = current.parentElement
    }
    return window
  }
}