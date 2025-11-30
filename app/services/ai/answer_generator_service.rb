require "google/cloud/ai_platform/v1"

module Ai
  class AnswerGeneratorService
    PROJECT_ID = ENV.fetch("GOOGLE_PROJECT_ID")
    MODEL_ID = "gemini-1.5-pro-preview-0409" # O gemini-1.0-pro según disponibilidad
    # Máximo de caracteres permitidos en el contexto antes de truncar
    MAX_CONTEXT_CHARS = 15_000

    def initialize(context_chunks, user_question)
      @context = self.class.build_context_with_citations(context_chunks)
      @question = user_question
      @client = VertexAiClient.client
    end

    def call
      prompt = build_prompt
      generate_content(prompt)
    end

    private

    def self.build_context_with_citations(chunks)
      chunks.map do |chunk|
        "[ID del fragmento: #{chunk.id}] Cita el ID si usas esta información.\n#{chunk.content}"
      end.join("\n\n")
    end

    def build_prompt
      # Truncado simple: no permitir que el contexto supere MAX_CONTEXT_CHARS
      context = @context.to_s
      if context.length > MAX_CONTEXT_CHARS
        context = context[0, MAX_CONTEXT_CHARS]
        # Indicador corto para saber que fue truncado (útil para debugging / UX)
        context += "\n\n[Contexto truncado por exceder #{MAX_CONTEXT_CHARS} caracteres]"
      end

      # Prompt Engineering: Instrucciones estrictas para evitar alucinaciones
      <<~TEXT
        Actúa como un profesor experto en programación y mentor técnico.
        Utiliza la siguiente información de contexto (Contexto) para responder a la pregunta del estudiante.

        Reglas:
        1. Si la respuesta no está en el contexto, di "No tengo información suficiente en los documentos proporcionados".
        2. Incluye ejemplos de código si el contexto los tiene.
        3. Al final de cada parte de la respuesta que se base en el contexto, cita los IDs de los fragmentos que utilizaste, por ejemplo: [ID del fragmento: 123].
        4. Sé conciso y pedagógico.

        Contexto:
        #{context}

        Pregunta del estudiante:
        #{@question}
      TEXT
    end

    def generate_content(prompt_text)
      endpoint_path = "projects/#{PROJECT_ID}/locations/#{VertexAIClient::REGION}/publishers/google/models/#{MODEL_ID}"

      # Estructura para Gemini (diferente a embeddings)
      instance = Google::Protobuf::Value.new(
        struct_value: Google::Protobuf::Struct.new(
          fields: {
            "contents" => Google::Protobuf::Value.new(
              list_value: Google::Protobuf::ListValue.new(
                values: [
                  Google::Protobuf::Value.new(
                    struct_value: Google::Protobuf::Struct.new(
                      fields: {
                        "role" => Google::Protobuf::Value.new(string_value: "user"),
                        "parts" => Google::Protobuf::Value.new(
                          list_value: Google::Protobuf::ListValue.new(
                            values: [
                              Google::Protobuf::Value.new(
                                struct_value: Google::Protobuf::Struct.new(
                                  fields: {
                                    "text" => Google::Protobuf::Value.new(string_value: prompt_text)
                                  }
                                )
                              )
                            ]
                          )
                        )
                      }
                    )
                  )
                ]
              )
            ),
            "generation_config" => Google::Protobuf::Value.new(
              struct_value: Google::Protobuf::Struct.new(
                fields: {
                  "temperature" => Google::Protobuf::Value.new(number_value: 0.2), # Baja temperatura para respuestas más factuales
                  "max_output_tokens" => Google::Protobuf::Value.new(number_value: 1024)
                }
              )
            )
          }
        )
      )

      request = Google::Cloud::AIPlatform::V1::PredictRequest.new(
        endpoint: endpoint_path,
        instances: [instance]
      )

      response = @client.predict(request)
      
      # Parsear respuesta de Gemini
      # predictions[0] -> content -> parts[0] -> text
      prediction = response.predictions.first
      content_struct = prediction.struct_value.fields
      # Nota: La estructura de respuesta exacta puede variar ligeramente según la versión de la API
      # Es recomendable inspeccionar 'response' si falla la ruta de acceso.
      
      # Acceso seguro a la respuesta de texto
      candidates = prediction.struct_value.fields["candidates"].list_value.values.first
      content = candidates.struct_value.fields["content"].struct_value
      parts = content.fields["parts"].list_value.values.first
      parts.struct_value.fields["text"].string_value
    rescue StandardError => e
      Rails.logger.error({
        error: e.message,
        backtrace: e.backtrace
      })

      # Lanzar un error personalizado para que el Job lo reintente
      raise AiGenerationError, "Fallo temporal de Vertex AI" 
    end
  end
end