import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  submit() {
    const btn = this.buttonTarget
    btn.disabled = true
    btn.innerHTML = `Generating… <span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>`
  }
}
