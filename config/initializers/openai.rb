require "openai"

OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:openai_api_key)
  config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", "") # Opcional
end
