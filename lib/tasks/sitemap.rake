namespace :sitemap do
  desc "Generate the sitemap and ping search engines"
  task generate_and_ping: :environment do
    # Define o host explicitamente
    host = Rails.env.production? ? "https://nutriplanbrasil.com.br" : "http://localhost:3000"
    SitemapGenerator::Sitemap.default_host = host
    
    # Gera o sitemap
    puts "Gerando sitemap..."
    SitemapGenerator::Sitemap.verbose = true
    SitemapGenerator::Sitemap.create
    
    # Notifica os motores de busca sobre o novo sitemap (apenas em produção)
    if Rails.env.production?
      puts "Notificando motores de busca..."
      SitemapGenerator::Sitemap.ping_search_engines
      puts "Sitemap gerado e motores de busca notificados com sucesso!"
    else
      puts "Sitemap gerado com sucesso! (Notificação de motores de busca ignorada em ambiente de desenvolvimento)"
    end
  end
end
