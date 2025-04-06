class SubscriptionsController < ApplicationController
  before_action :set_plan, only: [:new, :create]
  
  def index
    @subscriptions = current_user.subscriptions.order(created_at: :desc)
    @active_subscription = current_user.active_subscription
    @current_plan = current_user.current_plan
  end
  
  def show
    @subscription = current_user.subscriptions.find(params[:id])
    @transactions = @subscription.transactions.recent.limit(10)
  end
  
  def new
    @subscription = Subscription.new(plan: @plan)
  end
  
  def create
    @subscription = current_user.subscriptions.new(plan: @plan)
    
    # Iniciar o processo de pagamento com o Mercado Pago
    payment_service = MercadoPagoService.new
    payment_result = payment_service.create_payment_preference(
      user: current_user,
      plan: @plan,
      subscription: @subscription
    )
    
    if payment_result[:success]
      @subscription.mercado_pago_subscription_id = payment_result[:subscription_id]
      
      if @subscription.save
        # Criar a transação inicial
        @subscription.transactions.create(
          user: current_user,
          amount: @plan.price,
          description: "Assinatura do plano #{@plan.name}",
          mercado_pago_transaction_id: payment_result[:transaction_id],
          status: 'pending' # Status inicial como pendente
        )
        
        # Registrar o redirecionamento nos logs
        Rails.logger.info("Redirecionando para URL de pagamento: #{payment_result[:init_point]}")
        
        # Armazenar a URL de pagamento na sessão e redirecionar para a página intermediária
        session[:payment_url] = payment_result[:init_point]
        redirect_to payment_redirect_subscription_path(@subscription)
      else
        Rails.logger.error("Erro ao salvar assinatura: #{@subscription.errors.full_messages.join(', ')}")
        flash.now[:alert] = "Erro ao criar assinatura: #{@subscription.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    else
      Rails.logger.error("Erro ao processar pagamento: #{payment_result[:error]}")
      flash.now[:alert] = "Erro ao processar pagamento: #{payment_result[:error]}"
      render :new, status: :unprocessable_entity
    end
  end
  
  def cancel
    @subscription = current_user.subscriptions.find(params[:id])
    
    if @subscription.cancel!
      flash[:notice] = "Sua assinatura foi cancelada com sucesso."
    else
      flash[:alert] = "Não foi possível cancelar sua assinatura. Por favor, tente novamente."
    end
    
    redirect_to subscriptions_path
  end
  
  def payment_redirect
    @payment_url = session[:payment_url]
    session.delete(:payment_url) # Limpar a sessão após uso
    
    if @payment_url.blank?
      flash[:alert] = "URL de pagamento não encontrada. Por favor, tente novamente."
      redirect_to subscriptions_path
    end
  end
  
  def success
    # Se o usuário retornou da página de pagamento com sucesso, ativamos a assinatura
    if params[:external_reference].present?
      @subscription = current_user.subscriptions.find_by(id: params[:external_reference])
      
      if @subscription && @subscription.status == 'pending'
        # Buscar informações do pagamento no Mercado Pago
        payment_service = MercadoPagoService.new
        payment_info = payment_service.get_payment_info(params[:payment_id]) if params[:payment_id].present?
        
        Rails.logger.info("Pagamento retornado com sucesso: #{payment_info.inspect}")
        
        # Ativar a assinatura manualmente se o webhook não processou ainda
        @subscription.activate!
        
        # Atualizar a transação se existir
        if params[:payment_id].present?
          transaction = @subscription.transactions.find_by(mercado_pago_transaction_id: params[:payment_id])
          transaction&.update(status: 'approved')
        end
        
        flash[:notice] = "Sua assinatura foi ativada com sucesso!"
      end
    end
    
    # Redirecionar para a página de assinaturas
    redirect_to subscriptions_path
  end
  
  private
  
  def set_plan
    @plan = Plan.active.find(params[:plan_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Plano não encontrado ou indisponível."
    redirect_to plans_path
  end
end
