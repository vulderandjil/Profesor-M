module Ai
  class VertexAiClient
    REGION = ENV.fetch("GOOGLE_REGION", "us-central1").freeze
    ENDPOINT = "#{REGION}-aiplatform.googleapis.com".freeze

    def self.client
      @client ||= Google::Cloud::AIPlatform::V1::PredictionService::Client.new do |config|
        config.endpoint = ENDPOINT
        # AGREGA ESTA LÍNEA:
        config.credentials = ENV.fetch("GOOGLE_CREDENTIALS")
      end
    end
  end
end