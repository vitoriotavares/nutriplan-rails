module SeoHelper
  # Define metadados SEO para a página atual
  # 
  # @param options [Hash] opções de metadados
  # @option options [String] :title Título da página
  # @option options [String] :description Meta description da página
  # @option options [String] :keywords Palavras-chave para a página
  # @option options [String] :canonical_url URL canônica da página
  # @option options [String] :image URL da imagem para compartilhamento
  # @option options [Boolean] :no_index Define se a página deve ser indexada
  # @option options [Hash] :og Opções específicas para Open Graph
  # @option options [Hash] :twitter Opções específicas para Twitter Cards
  def set_meta_tags(options = {})
    @title = options[:title] if options[:title].present?
    @meta_description = options[:description] if options[:description].present?
    @meta_keywords = options[:keywords] if options[:keywords].present?
    @canonical_url = options[:canonical_url] if options[:canonical_url].present?
    @no_index = options[:no_index] || false
    
    # Open Graph
    if options[:og].present?
      @og_title = options[:og][:title] if options[:og][:title].present?
      @og_description = options[:og][:description] if options[:og][:description].present?
      @og_image = options[:og][:image] if options[:og][:image].present?
    end
    
    # Twitter Cards
    if options[:twitter].present?
      @twitter_title = options[:twitter][:title] if options[:twitter][:title].present?
      @twitter_description = options[:twitter][:description] if options[:twitter][:description].present?
      @twitter_image = options[:twitter][:image] if options[:twitter][:image].present?
    end
    
    # Imagem padrão para compartilhamento
    @og_image ||= options[:image] if options[:image].present?
    @twitter_image ||= options[:image] if options[:image].present?
  end
  
  # Gera markup Schema.org para uma página
  #
  # @param type [String] tipo de schema (Article, Product, etc)
  # @param data [Hash] dados do schema
  # @return [String] markup JSON-LD
  def schema_org_markup(type, data = {})
    schema = {
      '@context' => 'https://schema.org',
      '@type' => type
    }.merge(data)
    
    @schema_org_data ||= []
    @schema_org_data << schema
  end
  
  # Gera markup Schema.org para breadcrumbs
  #
  # @param breadcrumbs [Array<Hash>] array de hashes com :name e :url
  # @return [String] markup JSON-LD para breadcrumbs
  def breadcrumb_schema_markup(breadcrumbs)
    items = breadcrumbs.map.with_index do |crumb, index|
      {
        '@type' => 'ListItem',
        'position' => index + 1,
        'name' => crumb[:name],
        'item' => crumb[:url]
      }
    end
    
    schema = {
      '@context' => 'https://schema.org',
      '@type' => 'BreadcrumbList',
      'itemListElement' => items
    }
    
    @schema_org_data ||= []
    @schema_org_data << schema
  end
  
  # Renderiza todos os dados de Schema.org como scripts JSON-LD
  # Este método deve ser chamado na view
  def render_schema_org_data
    return unless @schema_org_data.present?
    
    @schema_org_data.map do |schema|
      content_tag :script, schema.to_json.html_safe, type: 'application/ld+json'
    end.join.html_safe
  end
end
