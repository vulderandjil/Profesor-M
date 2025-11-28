class MessagesController < ApplicationController
  def create
    @chat_session = ChatSession.find(params[:chat_session_id])
    @message = @chat_session.messages.new(message_params)
    @message.role = :user

    if @message.save
      # 1. Renderizamos el mensaje del usuario de inmediato (Turbo)
      # 2. Disparamos el Job para que la IA responda en segundo plano
      AiResponseJob.perform_later(@chat_session.id)
      
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat_session }
      end
    else
      # Manejo de errores simple
      redirect_to @chat_session, alert: "No se pudo enviar el mensaje"
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end