class AiResponseJob < ApplicationJob

  def perform(chat_session_id)
    chat_session = ChatSession.find(chat_session_id)
    
    # Recuperar el último mensaje del usuario para usarlo como query
    user_message = chat_session.messages.where(role: :user).last.content

    # 1. Buscar contexto (RAG)
    # Nota: Asumimos que ya tienes tu SearchService funcional
    context_chunks = Documents::SearchService.new(chat_session.topic_id, user_message).call

    # 2. Generar respuesta (Gemini)
    # Nota: Asumimos que ya tienes tu AnswerGeneratorService funcional
    ai_text = Ai::AnswerGeneratorService.new(context_chunks, user_message).call

    # 3. Guardar respuesta de la IA
    ai_message = chat_session.messages.create!(
      role: :assistant,
      content: ai_text
    )

    # 4. Broadcast al frontend via Turbo Streams
    # Esto busca el div con id "messages" y le añade el nuevo mensaje parcial
    Turbo::StreamsChannel.broadcast_append_to(
      chat_session,
      target: "messages",
      partial: "messages/message",
      locals: { message: ai_message }
    )
  end
end