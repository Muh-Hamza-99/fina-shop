import { Controller } from "@hotwired/stimulus"

// Lowercases the subdomain as it's typed and previews the full store URL.
export default class extends Controller {
  static targets = [ "input", "preview" ]
  static values = { template: String }

  update({ params: { domain } }) {
    this.inputTarget.value = this.inputTarget.value.toLowerCase().replace(/\s+/g, "")

    const url = `${this.inputTarget.value || "…"}.${domain}`
    this.previewTarget.textContent = this.templateValue.replace("__url__", url)
  }
}
