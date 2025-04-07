# Set the host name for URL creation
if Rails.env.production?
  SitemapGenerator::Sitemap.default_host = "https://nutriplanbrasil.com.br"
else
  SitemapGenerator::Sitemap.default_host = "http://localhost:3000"
end

# The directory to write sitemaps to locally
SitemapGenerator::Sitemap.public_path = 'public/'

# Set this to a directory/path if you don't want to upload to the root of your `public_path`
SitemapGenerator::Sitemap.sitemaps_path = ''

# Instance of `SitemapGenerator::Builder` that helps create sitemap files
SitemapGenerator::Sitemap.create do
  # Adicionar páginas estáticas principais
  add root_path, changefreq: 'daily', priority: 1.0
  
  # Páginas de autenticação
  add login_path, changefreq: 'monthly', priority: 0.6
  add signup_path, changefreq: 'monthly', priority: 0.6
  
  # Páginas estáticas
  add '/termos', changefreq: 'monthly', priority: 0.5
  add '/privacidade', changefreq: 'monthly', priority: 0.5
  add '/contato', changefreq: 'monthly', priority: 0.7
  
  # Planos
  add plans_path, changefreq: 'weekly', priority: 0.9
  add '/planos/compare', changefreq: 'weekly', priority: 0.8
  
  # Planos alimentares (apenas para usuários autenticados, mas indexamos a lista)
  add food_plans_path, changefreq: 'weekly', priority: 0.7
  
  # Adicionar planos individuais (se existirem)
  if defined?(Plan)
    Plan.all.each do |plan|
      add plan_path(plan), lastmod: plan.updated_at, priority: 0.9
    end
  end
  
  # Adicionar artigos do blog (se existirem)
  # if defined?(Blog) && Blog.respond_to?(:published)
  #   Blog.published.find_each do |blog|
  #     add blog_path(blog), lastmod: blog.updated_at, priority: 0.7
  #   end
  # end
end
