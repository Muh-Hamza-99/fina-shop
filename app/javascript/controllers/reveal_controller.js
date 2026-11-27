import { Controller } from "@hotwired/stimulus"

// Adds the "in" class once the element scrolls into view, to play its entrance animation.
export default class extends Controller {
  connect() {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches || !("IntersectionObserver" in window)) {
      this.element.classList.add("in")
      return
    }

    this.observer = new IntersectionObserver(([ entry ]) => {
      if (entry.isIntersecting) {
        this.element.classList.add("in")
        this.observer.disconnect()
      }
    }, { threshold: 0.4 })
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
