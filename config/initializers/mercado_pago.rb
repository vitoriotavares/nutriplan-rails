require 'mercadopago'

# Configuração do SDK do Mercado Pago
# As credenciais serão carregadas do arquivo credentials.yml.enc
# Para configurar em desenvolvimento, use:
# rails credentials:edit
# E adicione:
# mercado_pago:
#   access_token: "YOUR_ACCESS_TOKEN"
#   public_key: "YOUR_PUBLIC_KEY"

# O SDK do Mercado Pago não precisa de configuração global
# Cada instância é inicializada com o access_token
# Exemplo: sdk = Mercadopago::SDK.new(access_token)
