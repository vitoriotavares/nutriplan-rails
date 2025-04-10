require 'mercadopago'

# Configuração do SDK do Mercado Pago
# As credenciais serão carregadas do arquivo credentials.yml.enc
# Para configurar em desenvolvimento, use:
# rails credentials:edit
# E adicione:
# mercado_pago:
#   test:
#     access_token: "TEST_ACCESS_TOKEN"
#     public_key: "TEST_PUBLIC_KEY"
#   production:
#     access_token: "PROD_ACCESS_TOKEN"
#     public_key: "PROD_PUBLIC_KEY"

module MercadoPago
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def client
      @client ||= Mercadopago::SDK.new(access_token)
    end

    def access_token
      configuration.test_mode ? test_access_token : production_access_token
    end

    def public_key
      configuration.test_mode ? test_public_key : production_public_key
    end

    def test_access_token
      Rails.application.credentials.dig(:mercado_pago, :test, :access_token)
    end

    def test_public_key
      Rails.application.credentials.dig(:mercado_pago, :test, :public_key)
    end

    def production_access_token
      Rails.application.credentials.dig(:mercado_pago, :production, :access_token)
    end

    def production_public_key
      Rails.application.credentials.dig(:mercado_pago, :production, :public_key)
    end
  end

  class Configuration
    attr_accessor :test_mode

    def initialize
      @test_mode = !Rails.env.production?
    end
  end
end

# Configuração padrão
MercadoPago.configure do |config|
  # Em ambientes de desenvolvimento e teste, usa o modo de teste por padrão
  # Em produção, usa o modo de produção
  config.test_mode = !Rails.env.production?
end
