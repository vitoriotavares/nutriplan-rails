class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  include SeoHelper
  
  def index
    # Configuração de SEO para a página inicial
    set_meta_tags(
      title: "NutriPlan - Planos Alimentares Personalizados",
      description: "Crie planos alimentares personalizados com base em suas necessidades nutricionais. Acompanhamento profissional e receitas saudáveis.",
      keywords: "plano alimentar, nutrição, dieta personalizada, saúde, emagrecimento, nutricionista online",
      image: asset_url("home-banner.jpg"),
      og: {
        title: "NutriPlan - Transforme sua alimentação",
        description: "Planos alimentares personalizados para atingir seus objetivos de saúde e bem-estar."
      },
      twitter: {
        title: "NutriPlan - Alimentação saudável personalizada",
        description: "Descubra como uma alimentação personalizada pode transformar sua saúde."
      }
    )
    
    # Schema.org para a página inicial
    schema_org_markup("WebSite", {
      name: "NutriPlan",
      url: root_url,
      potentialAction: {
        "@type": "SearchAction",
        "target": "#{root_url}search?q={search_term_string}",
        "query-input": "required name=search_term_string"
      },
      description: "Plataforma de planos alimentares personalizados",
      publisher: {
        "@type": "Organization",
        "name": "NutriPlan",
        "logo": {
          "@type": "ImageObject",
          "url": asset_url("logo.png")
        }
      }
    })
  end
end