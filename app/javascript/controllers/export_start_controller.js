import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    const form = document.getElementById('export-form')
    if (!form) return

    this.element.querySelectorAll('.copied-setting').forEach(n => n.remove())
    const formData = new FormData(form)

    const add = (name, value) => {
      if (!name.startsWith('export[settings]')) return
      const input = document.createElement('input')
      input.type = 'hidden'; input.name = name; input.value = value; input.className = 'copied-setting'
      this.element.appendChild(input)
    }

    formData.forEach(add)
    form.querySelectorAll('input[type=checkbox][name^="export[settings]"]').forEach(checkbox => {
      if (!formData.has(checkbox.name)) add(checkbox.name, '0')
    })
  }
}
