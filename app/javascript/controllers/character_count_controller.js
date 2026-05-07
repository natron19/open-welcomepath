import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]
  static values  = { max: Number }

  connect() {
    this.update()
  }

  update() {
    const current = this.inputTarget.value.length
    const max     = this.maxValue
    this.counterTarget.textContent = `${current} / ${max}`
    this.counterTarget.classList.toggle("text-danger", current >= max)
  }
}
