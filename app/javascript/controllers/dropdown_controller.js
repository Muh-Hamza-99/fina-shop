import { Controller } from "@hotwired/stimulus"

// Closes a <details> dropdown on Escape or a click outside it.
export default class extends Controller {
  close() {
    this.element.open = false
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
