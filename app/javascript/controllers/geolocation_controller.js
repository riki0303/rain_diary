import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["latitude", "longitude"];

  connect() {
    if (!navigator.geolocation) {
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) => this.handleSuccess(position),
      () => {}, // 座標未取得はサーバー側バリデーションで弾く
      { timeout: 10000 }
    );
  }

  handleSuccess(position) {
    const { latitude, longitude } = position.coords;

    // diary#new
    if (this.hasLatitudeTarget && this.hasLongitudeTarget) {
      this.latitudeTarget.value = latitude;
      this.longitudeTarget.value = longitude;
      return;
    }

    // diary#index
    const url = new URL(window.location.href);
    if (url.searchParams.has("latitude") && url.searchParams.has("longitude")) {
      return;
    }
    url.searchParams.set("latitude", latitude);
    url.searchParams.set("longitude", longitude);
    window.location.replace(url.toString());
  }
}
