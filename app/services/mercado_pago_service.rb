class MercadoPagoService
  def initialize(test_mode: nil)
    # Se test_mode for especificado, usa esse valor
    # Caso contrário, usa a configuração global
    @test_mode = test_mode.nil? ? MercadoPago.configuration.test_mode : test_mode
    @sdk = Mercadopago::SDK.new(access_token)
  end
  
  # Alterna entre modo de teste e produção
  def toggle_test_mode(enabled)
    @test_mode = enabled
    @sdk = Mercadopago::SDK.new(access_token)
  end
  
  # Retorna o token de acesso apropriado com base no modo atual
  def access_token
    @test_mode ? MercadoPago.test_access_token : MercadoPago.production_access_token
  end
  
  # Retorna a chave pública apropriada com base no modo atual
  def public_key
    @test_mode ? MercadoPago.test_public_key : MercadoPago.production_public_key
  end
  
  # Cria uma preferência de pagamento para assinatura
  def create_payment_preference(user:, plan:, subscription:)
    Rails.logger.info("Iniciando criação de preferência de pagamento para usuário #{user.id}, plano #{plan.id}")
    Rails.logger.info("Modo de teste: #{@test_mode ? 'ATIVADO' : 'DESATIVADO'}")
    
    # Garantir que a assinatura tenha um ID antes de criar a preferência
    # Se a assinatura ainda não foi salva, salvamos temporariamente
    if subscription.new_record?
      subscription.save(validate: false)
      Rails.logger.info("Assinatura temporária criada com ID: #{subscription.id}")
    end
    
    preference_data = {
      items: [
        {
          id: plan.id.to_s,
          title: "Assinatura #{plan.name} - NutriPlan",
          description: plan.description,
          quantity: 1,
          currency_id: "BRL",
          unit_price: plan.price.to_f
        }
      ],
      payer: {
        email: user.email,
        name: user.profile&.name || user.email,
        identification: {
          type: "CPF",
          number: user.profile&.document
        }
      },
      back_urls: {
        success: success_payment_url(external_reference: subscription.id.to_s),
        pending: pending_payment_url,
        failure: failure_payment_url
      },
      auto_return: "approved",
      external_reference: subscription.id.to_s,
      notification_url: webhook_url
    }
    
    Rails.logger.info("Referência externa: #{subscription.id}")
    Rails.logger.info("URLs de callback configuradas: success=#{success_payment_url(external_reference: subscription.id.to_s)}, pending=#{pending_payment_url}, failure=#{failure_payment_url}")
    Rails.logger.info("URL de webhook: #{webhook_url}")
    
    begin
      Rails.logger.info("Enviando requisição para o Mercado Pago")
      preference_response = @sdk.preference.create(preference_data)
      Rails.logger.info("Resposta do Mercado Pago: #{preference_response.inspect}")
      
      # O status 201 indica que a preferência foi criada com sucesso
      if preference_response[:status] == "201" || preference_response[:status] == 201
        Rails.logger.info("Preferência de pagamento criada com sucesso: #{preference_response[:response]['id']}")
        {
          success: true,
          init_point: preference_response[:response]["init_point"],
          subscription_id: preference_response[:response]["id"],
          transaction_id: preference_response[:response]["id"]
        }
      else
        Rails.logger.error("Erro ao criar preferência de pagamento: #{preference_response.inspect}")
        { success: false, error: "Erro ao criar preferência de pagamento" }
      end
    rescue => e
      Rails.logger.error("Erro no Mercado Pago: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      { success: false, error: e.message }
    end
  end
  
  # Processa um webhook de pagamento
  def process_webhook(topic:, id:)
    return { success: false, error: "Tópico não suportado" } unless topic == "payment"
    
    begin
      payment_info = @sdk.payment.get(id)
      
      if payment_info[:status] == "200"
        payment_data = payment_info[:response]
        external_reference = payment_data["external_reference"]
        status = payment_data["status"]
        
        subscription = Subscription.find_by(id: external_reference)
        return { success: false, error: "Assinatura não encontrada" } unless subscription
        
        transaction = subscription.transactions.find_or_initialize_by(
          mercado_pago_transaction_id: payment_data["id"].to_s
        )
        
        transaction.update(
          user: subscription.user,
          amount: payment_data["transaction_amount"],
          status: map_payment_status(status),
          payment_method: payment_data["payment_method_id"],
          payment_details: payment_data,
          description: "Pagamento via #{payment_data['payment_type_id']}"
        )
        
        # Atualiza a assinatura se o pagamento foi aprovado
        if status == "approved"
          subscription.activate!
        end
        
        { success: true, transaction: transaction }
      else
        { success: false, error: "Erro ao obter informações do pagamento" }
      end
    rescue => e
      Rails.logger.error("Erro ao processar webhook: #{e.message}")
      { success: false, error: e.message }
    end
  end
  
  def create_additional_plan_payment(user:, transaction:, price:)
    preference_data = {
      items: [
        {
          id: "additional_plan",
          title: "Plano Alimentar Adicional - NutriPlan",
          description: "Compra de um plano alimentar adicional",
          quantity: 1,
          currency_id: "BRL",
          unit_price: price.to_f
        }
      ],
      payer: {
        email: user.email,
        name: user.profile&.name || user.email,
        identification: {
          type: "CPF",
          number: user.profile&.document
        }
      },
      back_urls: {
        success: success_additional_plans_url(external_reference: transaction.id),
        pending: pending_additional_plans_url,
        failure: failure_additional_plans_url
      },
      auto_return: "approved",
      external_reference: transaction.id.to_s,
      notification_url: webhook_url
    }
    
    begin
      preference = @sdk.preference.create(preference_data)
      
      # Atualizar a transação com os dados do pagamento
      transaction.update(
        payment_id: preference["id"],
        payment_data: preference.to_json
      )
      
      { success: true, payment_url: preference["init_point"] }
    rescue => e
      Rails.logger.error("Erro ao criar preferência de pagamento: #{e.message}")
      { success: false, error: e.message }
    end
  end
  
  def get_payment_info(payment_id)
    begin
      Rails.logger.info("Obtendo informações do pagamento #{payment_id}")
      payment_response = @sdk.payment.get(payment_id)
      
      if payment_response[:status] == "200" || payment_response[:status] == 200
        Rails.logger.info("Informações do pagamento obtidas com sucesso: #{payment_response[:response].inspect}")
        return payment_response[:response]
      else
        Rails.logger.error("Erro ao obter informações do pagamento: #{payment_response.inspect}")
        return nil
      end
    rescue => e
      Rails.logger.error("Erro ao obter informações do pagamento #{payment_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return nil
    end
  end
  
  private
  
  def map_payment_status(mercado_pago_status)
    case mercado_pago_status
    when "approved"
      "approved"
    when "pending", "in_process"
      "pending"
    when "rejected"
      "rejected"
    else
      "pending"
    end
  end
  
  def webhook_url
    host = ENV['NGROK_HOST'] || Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port]
    url_options = { host: host }
    url_options[:port] = port if port && !ENV['NGROK_HOST']
    
    Rails.application.routes.url_helpers.mercado_pago_webhook_url(url_options)
  end
  
  def success_additional_plans_url(external_reference:)
    host = ENV['NGROK_HOST'] || Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port]
    url_options = { host: host, external_reference: external_reference }
    url_options[:port] = port if port && !ENV['NGROK_HOST']
    
    Rails.application.routes.url_helpers.success_additional_plans_url(url_options)
  end
  
  def pending_additional_plans_url
    host = ENV['NGROK_HOST'] || Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port]
    url_options = { host: host }
    url_options[:port] = port if port && !ENV['NGROK_HOST']
    
    Rails.application.routes.url_helpers.pending_additional_plans_url(url_options)
  end
  
  def failure_additional_plans_url
    host = ENV['NGROK_HOST'] || Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port]
    url_options = { host: host }
    url_options[:port] = port if port && !ENV['NGROK_HOST']
    
    Rails.application.routes.url_helpers.failure_additional_plans_url(url_options)
  end
  
  def success_payment_url(external_reference: nil)
    host = ENV['NGROK_HOST'] || Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port]
    url_options = { host: host }
    url_options[:port] = port if port && !ENV['NGROK_HOST']
    
    # Incluir external_reference e payment_id nos parâmetros de sucesso
    Rails.application.routes.url_helpers.success_subscriptions_url(
      url_options.merge(
        external_reference: external_reference,
        payment_id: '%s'
      )
    ).gsub('%s', '')
  end
  
  def pending_payment_url
    host = ENV['NGROK_HOST'] || Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port]
    url_options = { host: host }
    url_options[:port] = port if port && !ENV['NGROK_HOST']
    
    Rails.application.routes.url_helpers.pending_subscriptions_url(url_options)
  end
  
  def failure_payment_url
    host = ENV['NGROK_HOST'] || Rails.application.config.action_mailer.default_url_options[:host]
    port = Rails.application.config.action_mailer.default_url_options[:port]
    url_options = { host: host }
    url_options[:port] = port if port && !ENV['NGROK_HOST']
    
    Rails.application.routes.url_helpers.failure_subscriptions_url(url_options)
  end
end
