import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="visited-links"
export default class extends Controller {
    visit(event) {
        event.target.closest("a").classList.add("visited");
    }
}
