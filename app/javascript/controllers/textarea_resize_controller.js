import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Asegurar estilos necesarios
    this.element.style.overflow = 'hidden'
    this.element.style.resize = 'none'

    // Ajuste inicial
    this.resize()

    // Escuchar entrada para ajustar mientras se escribe
    this.boundResize = this.resize.bind(this)
    this.element.addEventListener('input', this.boundResize)
  }

  disconnect() {
    if (this.boundResize) {
      this.element.removeEventListener('input', this.boundResize)
    }
  }

  resize() {
    this.element.style.height = 'auto'
    const newHeight = this.element.scrollHeight
    this.element.style.height = `${newHeight}px`
  }
}
