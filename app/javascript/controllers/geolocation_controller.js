import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "submit", "message", "newLink"]
  static values = { mode: { type: String, default: "form" } }

  connect() {
    if (!navigator.geolocation) {
      this.handleError()
      return
    }
    navigator.geolocation.getCurrentPosition(
      (position) => this.handleSuccess(position),
      () => this.handleError(),
      { timeout: 10000 }
    )
  }

  handleSuccess(position) {
    const { latitude, longitude } = position.coords
    debugger

    if (this.modeValue === "index") {
      const searchParams = new URLSearchParams(window.location.search)
      if (!searchParams.has("latitude") && !searchParams.has("longitude")) {
        const url = new URL(window.location.href)
        url.searchParams.set("latitude", latitude)
        url.searchParams.set("longitude", longitude)
        window.location.replace(url.toString())
        return
      }
    }

    if (this.hasLatitudeTarget) {
      this.latitudeTarget.value = latitude
    }
    if (this.hasLongitudeTarget) {
      this.longitudeTarget.value = longitude
    }
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = false
    }
    if (this.hasMessageTarget) {
      this.messageTarget.classList.add("d-none")
    }
    if (this.hasNewLinkTarget) {
      this.newLinkTarget.classList.remove("d-none")
    }
  }

  handleError() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
    }
    if (this.hasMessageTarget) {
      this.messageTarget.classList.remove("d-none")
    }
    if (this.hasNewLinkTarget) {
      this.newLinkTarget.classList.add("d-none")
    }
  }
}
