import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topButton", "bottomButton"]

  static values = {
    topThreshold: { type: Number, default: 300 },
    bottomShowThreshold: { type: Number, default: 320 },
    bottomHideThreshold: { type: Number, default: 180 }
  }

  connect() {
    this.scrollContainer = this.resolveScrollContainer()
    this.updateVisibility = this.updateVisibility.bind(this)
    this.bottomVisible = false

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
    const distance = this.distanceFromBottom()

    if (!this.bottomVisible && distance >= this.bottomShowThresholdValue) {
      this.bottomVisible = true
    } else if (this.bottomVisible && distance <= this.bottomHideThresholdValue) {
      this.bottomVisible = false
    }

    const topVisible = this.scrollTop() > this.topThresholdValue

    this.topButtonTargets.forEach((button) => {
      button.toggleAttribute("data-visible", topVisible)
      button.toggleAttribute("data-bottom-hidden", !this.bottomVisible)
    })

    this.bottomButtonTargets.forEach((button) => {
      button.toggleAttribute("data-visible", this.bottomVisible)
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

  distanceFromBottom() {
    return this.scrollHeight() - (this.scrollTop() + this.clientHeight())
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