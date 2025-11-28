import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Scroll al fondo al cargar la página
    this.scrollToBottom()
    
    // Configurar un observador para detectar nuevos mensajes
    this.observer = new MutationObserver(() => {
      this.scrollToBottom()
    })
    
    // Observar cambios en el div "messages"
    const messagesNode = document.getElementById("messages")
    if (messagesNode) {
      this.observer.observe(messagesNode, { childList: true, subtree: true })
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}