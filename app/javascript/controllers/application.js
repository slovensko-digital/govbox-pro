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
document.addEventListener('turbo:before-cache', function({ target}) {
    const setOpenAsFalse = (attribute) => {
        const element = target.querySelector(`[${attribute}="true"]`)
        element?.setAttribute(attribute, "false")
    }

    const queryAllAndModify = (selector, modify) => {
        target.querySelectorAll(selector).forEach(modify)
    }

    const addHiddenClass = () => {
        queryAllAndModify("[data-turbo-temporary-hide]", (elm) => {
            if (!elm.classList.contains('hidden')) {
                elm.classList.add('hidden')
            }
        })
    }

    const removeAlerts = () => {
        queryAllAndModify("[data-controller=\"dismissible-alert\"][data-turbo-temporary-hide]", (elm) => {
            elm.remove()
        })
    }

    addHiddenClass()
    setOpenAsFalse('data-slideover-open-value')
    setOpenAsFalse('data-dropdown-open-value')
    removeAlerts()
})

export { application }