import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["banner"];

  connect() {
    if (!("Notification" in window)) {
      this.updateStatus("Notifications are not supported.");
      return;
    }

    this.updateStatus(Notification.permission);
  }

  requestPermission() {
    if ("Notification" in window) {
      // Request permission from the user to send notifications
      Notification.requestPermission().then((permission) => {
        if (permission === "granted") {
          // If permission is granted, register the service worker
          this.registerServiceWorker();
        } else if (permission === "denied") {
          console.warn("User rejected to allow notifications.");
        } else {
          console.warn("User still didn't give an answer about notifications.");
        }
        this.updateStatus(permission);
      });
    } else {
      console.warn("Push notifications not supported.");
    }
  }

  updateStatus(message) {
    if (this.hasBannerTarget) {
      if (message != "granted") {
        this.bannerTarget.classList.remove("hidden");
      } else {
        this.bannerTarget.classList.add("hidden");
      }
    }
  }

  registerServiceWorker() {
    // Check if the browser supports service workers
    if ("serviceWorker" in navigator) {
      // Register the service worker script (service_worker.js)
      navigator.serviceWorker
        .register(window.location.origin + "/service-worker.js")
        .then((serviceWorkerRegistration) => {
          // Check if a subscription to push notifications already exists
          serviceWorkerRegistration.pushManager.getSubscription().then((existingSubscription) => {
            if (!existingSubscription) {
              // If no subscription exists, subscribe to push notifications
              serviceWorkerRegistration.pushManager
                .subscribe({
                  userVisibleOnly: true,
                  applicationServerKey: new Uint8Array(
                    JSON.parse(this.element.getAttribute("data-application-server-key"))
                  ),
                })
                .then((subscription) => {
                  // Save the subscription on the server
                  this.saveSubscription(subscription);
                });
            }
          });
        })
        .catch((error) => {
          console.error("Error during registration Service Worker:", error);
        });
    }
  }

  saveSubscription(subscription) {
    // Extract necessary subscription data
    const endpoint = subscription.endpoint;
    const p256dh = btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey("p256dh"))));
    const auth = btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey("auth"))));

    // Send the subscription data to the server
    fetch("/push_endpoints", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
      },
      body: JSON.stringify({ endpoint, p256dh, auth }),
    })
      .then((response) => {
        if (response.ok) {
          console.log("Subscription successfully saved on the server.");
        } else {
          console.error("Error saving subscription on the server.");
        }
      })
      .catch((error) => {
        console.error("Error sending subscription to the server:", error);
      });
  }
}
