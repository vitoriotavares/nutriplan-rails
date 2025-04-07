require_relative "production"

Rails.application.configure do
  # Permitir hosts locais para testes em ambiente de produção
  config.hosts.clear
  config.hosts << "localhost"
  config.hosts << "127.0.0.1"
  config.hosts << "::1"
  
  # Desabilitar SSL para testes locais
  config.force_ssl = false
  
  # Configurar para servir assets estáticos
  config.public_file_server.enabled = true
end
