import {Controller} from "@hotwired/stimulus"
import {Sortable} from "@shopify/draggable";
import {post} from '@rails/request.js'

export default class extends Controller {
  static classes = ["draggable", "handle"]
  static targets = ["item", "submit"]
  static values = {url: String}

  connect() {
    this.sortable = new Sortable(this.element, {
      draggable: this.draggableClass,
      handle: this.handleClass,
      classes: {
        "source:dragging": "invisible",
      }
    })

    this.sortable.on('drag:stopped', async (e) => {
      // As of now, this is the only way to submit a PATCH request with Rails so Turbo updates the pages without a full reload

      const link = this.submitTarget;

      const urlSearchParams = new URLSearchParams({_method: 'patch'});
      this.itemTargets.map((item) => {
        urlSearchParams.append('filter_ids[]', item.dataset.id);
      });
      link.href = this.urlValue + '?' + urlSearchParams.toString();

      link.click()
    });
  }
}
