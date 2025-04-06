class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  
  def mercado_pago
    # Recebe notificações do Mercado Pago
    payment_service = MercadoPagoService.new
    
    begin
      if params[:topic] == "payment" && params[:id].present?
        payment_info = payment_service.get_payment_info(params[:id])
        
        if payment_info.present?
          process_payment(payment_info)
          head :ok
        else
          head :bad_request
        end
      else
        head :ok
      end
    rescue => e
      Rails.logger.error("Erro ao processar webhook do Mercado Pago: #{e.message}")
      head :internal_server_error
    end
  end
  
  private
  
  def process_payment(payment_info)
    external_reference = payment_info["external_reference"]
    status = payment_info["status"]
    
    Rails.logger.info("Processando pagamento com external_reference: #{external_reference}, status: #{status}")
    
    # Buscar a transação pelo external_reference
    transaction = Transaction.find_by(mercado_pago_transaction_id: payment_info["id"])
    
    if !transaction && external_reference.present?
      # Tenta buscar pelo external_reference se não encontrou pelo ID
      transaction = Transaction.find_by(id: external_reference)
    end
    
    if transaction
      Rails.logger.info("Transação encontrada: #{transaction.id}, atualizando status para: #{status}")
      
      # Atualizar o status da transação
      transaction.update(
        status: status,
        payment_method: payment_info["payment_type_id"],
        payment_details: payment_info
      )
      
      # Processar de acordo com o tipo de transação
      if transaction.type_subscription?
        process_subscription_payment(transaction, status)
      elsif transaction.type_additional_plan?
        process_additional_plan_payment(transaction, status)
      end
    else
      Rails.logger.error("Transação não encontrada para external_reference: #{external_reference}")
    end
  end
  
  def process_subscription_payment(transaction, status)
    subscription = transaction.subscription
    
    Rails.logger.info("Processando pagamento de assinatura: #{subscription.id}, status: #{status}")
    
    if subscription && status == "approved"
      # Ativar a assinatura
      Rails.logger.info("Ativando assinatura: #{subscription.id}")
      subscription.update(status: "active") if subscription.status == "pending"
    elsif subscription && status == "rejected"
      # Marcar a assinatura como falha
      Rails.logger.info("Marcando assinatura como falha: #{subscription.id}")
      subscription.update(status: "failed") if subscription.status == "pending"
    end
  end
  
  def process_additional_plan_payment(transaction, status)
    user = transaction.user
    
    Rails.logger.info("Processando pagamento de plano adicional para usuário: #{user.id}, status: #{status}")
    
    if user && status == "approved"
      # Adicionar um plano alimentar adicional ao usuário
      Rails.logger.info("Adicionando plano alimentar adicional para usuário: #{user.id}")
      user.add_additional_food_plans(1)
    end
  end
end
