import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { scale: Boolean }

  connect() {
    this.observers = [];

    if (this.element.contentDocument?.readyState === "complete") this.setup();
  }

  disconnect() {
    this.stopObserving();
  }

  setup() {
    this.stopObserving();

    const body = this.element.contentDocument?.body;
    if (!body) return;

    body.style.height = "unset";
    body.style.minHeight = "unset";

    if (this.scaleValue) {
      body.style.transformOrigin = "0 0";
      this.observe(this.wrapper, () => this.scaleToFit(body));
    }

    this.observe(body, () => this.resizeToContent(body));
  }

  resizeToContent(body) {
    this.wrapper.style.height = `${this.contentHeight(body)}px`;
    this.wrapper.classList.remove("invisible");
  }

  scaleToFit(body) {
    const scale = (this.wrapper.clientWidth - 24) / body.scrollWidth;
    if (scale > 1) return;

    body.style.transform = `scale(${scale})`;
    this.wrapper.style.height = `${body.clientHeight * scale + 20}px`;
  }

  contentHeight(body) {
    const documentElement = body.ownerDocument.documentElement;

    return Math.max(body.scrollHeight, body.offsetHeight, documentElement.scrollHeight, documentElement.offsetHeight);
  }

  observe(target, callback) {
    const observer = new ResizeObserver(callback);

    observer.observe(target);
    this.observers.push(observer);
  }

  stopObserving() {
    this.observers.forEach((observer) => observer.disconnect());
    this.observers = [];
  }

  get wrapper() {
    return this.element.parentElement;
  }
}
