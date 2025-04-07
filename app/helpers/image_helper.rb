module ImageHelper
  # Renderiza uma imagem otimizada para SEO com lazy loading e atributos adequados
  #
  # @param source [String] caminho da imagem
  # @param alt [String] texto alternativo para a imagem
  # @param options [Hash] opções adicionais para a tag de imagem
  # @option options [String] :width largura da imagem
  # @option options [String] :height altura da imagem
  # @option options [String] :class classes CSS
  # @option options [Boolean] :lazy habilita lazy loading (padrão: true)
  # @option options [String] :loading tipo de carregamento (padrão: 'lazy')
  # @option options [String] :sizes atributo sizes para imagens responsivas
  # @option options [String] :srcset conjunto de fontes para imagens responsivas
  # @return [String] tag de imagem otimizada
  def optimized_image_tag(source, alt, options = {})
    # Configurações padrão
    default_options = {
      loading: options.fetch(:lazy, true) ? 'lazy' : 'eager',
      decoding: 'async',
      alt: alt
    }
    
    # Remover opção :lazy que não é um atributo HTML válido
    options.delete(:lazy)
    
    # Mesclar opções
    image_options = default_options.merge(options)
    
    # Garantir que width e height estejam presentes para evitar layout shifts
    unless image_options[:width].present? && image_options[:height].present?
      if source.present? && source.start_with?('/')
        # Tentar obter dimensões para imagens locais
        begin
          full_path = Rails.root.join('public', source.sub(/\A\//, ''))
          if File.exist?(full_path)
            require 'mini_magick'
            image = MiniMagick::Image.open(full_path)
            image_options[:width] ||= image.width
            image_options[:height] ||= image.height
          end
        rescue => e
          Rails.logger.error("Erro ao obter dimensões da imagem: #{e.message}")
        end
      end
    end
    
    # Adicionar classe para imagens responsivas se não houver classe definida
    if !image_options[:class].present?
      image_options[:class] = "max-w-full h-auto"
    end
    
    # Renderizar a tag de imagem
    image_tag(source, image_options)
  end
  
  # Gera um placeholder para imagens que ainda não carregaram
  #
  # @param width [Integer] largura do placeholder
  # @param height [Integer] altura do placeholder
  # @param text [String] texto a ser exibido no placeholder
  # @return [String] URL de dados do placeholder
  def image_placeholder(width, height, text = nil)
    text ||= "#{width}×#{height}"
    
    # Criar SVG base64 como placeholder
    svg = %{
      <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}" viewBox="0 0 #{width} #{height}">
        <rect width="#{width}" height="#{height}" fill="#e2e8f0"/>
        <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="14" text-anchor="middle" dominant-baseline="middle" fill="#64748b">#{text}</text>
      </svg>
    }.gsub(/\s+/, " ").strip
    
    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end
end
