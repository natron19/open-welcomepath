import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["actions", "loading"]

  submit() {
    if (this.hasActionsTarget) this.actionsTarget.classList.add("d-none")
    if (this.hasLoadingTarget) this.loadingTarget.classList.remove("d-none")
  }
}
