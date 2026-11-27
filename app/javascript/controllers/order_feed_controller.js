import { Controller } from "@hotwired/stimulus"

// Landing page dashboard preview: a new order slides in every few seconds.
export default class extends Controller {
  static targets = [ "list", "toast", "row" ]
  static values = { orders: Array, interval: { type: Number, default: 3200 } }

  connect() {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return
    this.index = this.listTarget.children.length
    this.timer = setInterval(() => this.addOrder(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  addOrder() {
    const [ initials, name, amount ] = this.ordersValue[this.index++ % this.ordersValue.length]
    const row = this.rowTarget.content.firstElementChild.cloneNode(true)
    row.classList.add("new")
    row.querySelector("[data-field=initials]").textContent = initials
    row.querySelector("[data-field=name]").textContent = name
    row.querySelector("[data-field=amount]").textContent = amount

    this.listTarget.prepend(row)
    this.listTarget.children[1]?.classList.remove("new")
    if (this.listTarget.children.length > 4) this.listTarget.lastElementChild.remove()

    this.toastTarget.style.animation = "none"
    this.toastTarget.offsetWidth
    this.toastTarget.style.animation = "lp-slidein .5s ease both"
  }
}
