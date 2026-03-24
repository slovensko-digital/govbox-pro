import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets =["topButton", "bottomButton"]

  connect() {
    this.scrollContainer = this.resolveScrollContainer()
    this.updateVisibility = this.updateVisibility.bind(this)

    this.scrollContainer.addEventListener("scroll", this.updateVisibility, { passive: true })
    window.addEventListener("resize", this.updateVisibility)

    this.resizeObserver = new ResizeObserver(this.updateVisibility)
    this.resizeObserver.observe(document.documentElement)

    this.updateVisibility()
    requestAnimationFrame(this.updateVisibility)
    setTimeout(this.updateVisibility, 150)
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
    this.scrollContainer.scrollTo({ top: this.scrollHeight(), behavior: "smooth" })
  }

  updateVisibility() {
    const scrollTop = this.scrollTop()
    const scrollHeight = this.scrollHeight()
    const clientHeight = this.clientHeight()

    const totalScrollable = scrollHeight - clientHeight
    if (totalScrollable < 100) {
      this.toggleButtons(false, false)
      return
    }

    const isCloserToBottom = scrollTop > (totalScrollable / 2)
    this.toggleButtons(isCloserToBottom, !isCloserToBottom)
  }

  toggleButtons(showTop, showBottom) {
    this.topButtonTargets.forEach((button) => {
      button.toggleAttribute("data-visible", showTop)
    })

    this.bottomButtonTargets.forEach((button) => {
      button.toggleAttribute("data-visible", showBottom)
    })
  }

  get isWindow() { return this.scrollContainer === window }

  scrollTop() {
    return this.isWindow ? (window.scrollY || document.documentElement.scrollTop || 0) : this.scrollContainer.scrollTop
  }

  scrollHeight() {
    return this.isWindow ? Math.max(document.body.scrollHeight, document.documentElement.scrollHeight) : this.scrollContainer.scrollHeight
  }

  clientHeight() {
    return this.isWindow ? (window.innerHeight || document.documentElement.clientHeight) : this.scrollContainer.clientHeight
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