# Configuração de cabeçalhos de segurança para melhorar o SEO e a segurança do site
SecureHeaders::Configuration.default do |config|
  # Política de segurança de conteúdo (CSP)
  config.csp = {
    default_src: %w('self' https:),
    script_src: %w('self' 'unsafe-inline' https://cdnjs.cloudflare.com https://fonts.googleapis.com),
    style_src: %w('self' 'unsafe-inline' https://cdnjs.cloudflare.com https://fonts.googleapis.com),
    img_src: %w('self' data: https:),
    font_src: %w('self' data: https://cdnjs.cloudflare.com https://fonts.gstatic.com),
    connect_src: %w('self' https:),
    frame_src: %w('self' https:),
    frame_ancestors: %w('self'),
    form_action: %w('self'),
    base_uri: %w('self'),
    object_src: %w('none'),
    upgrade_insecure_requests: true
  }

  # Cabeçalho X-Frame-Options para evitar clickjacking
  config.x_frame_options = "SAMEORIGIN"

  # Cabeçalho X-XSS-Protection para proteção contra XSS
  config.x_xss_protection = "1; mode=block"

  # Cabeçalho X-Content-Type-Options para evitar MIME sniffing
  config.x_content_type_options = "nosniff"

  # Cabeçalho Referrer-Policy para controlar informações de referência
  config.referrer_policy = "strict-origin-when-cross-origin"

  # Cabeçalhos para políticas de domínio cruzado
  config.x_permitted_cross_domain_policies = "none"
end
