import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Import and register all TailwindCSS Components
import { Alert, Autosave, Dropdown, Modal, Tabs, Popover, Toggle, Slideover } from "tailwindcss-stimulus-components"
application.register('alert', Alert)
application.register('autosave', Autosave)
application.register('dropdown', Dropdown)
application.register('modal', Modal)
application.register('tabs', Tabs)
application.register('popover', Popover)
application.register('toggle', Toggle)
application.register('slideover', Slideover)
document.addEventListener('turbo:before-cache', function(event) {
    event.target.querySelectorAll("[data-turbo-temporary-hide]").forEach((elm) => {
        elm.style = 'display: none';
    })
});

if (window.history.state && window.history.state.turbo) {
    window.addEventListener("popstate", function () {
        location.reload(true);
    });
}

export { application }