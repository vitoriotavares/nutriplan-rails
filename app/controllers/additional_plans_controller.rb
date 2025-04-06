class AdditionalPlansController < ApplicationController
  before_action :set_price
  
  def new
    @title = "Comprar Plano Adicional - NutriPlan"
  end
  
  def create
    # Criar uma transação para o plano adicional
    transaction = current_user.transactions.new(
      amount: @price,
      status: 'pending',
      transaction_type: 'additional_plan',
      description: 'Compra de plano alimentar adicional'
    )
    
    if transaction.save
      # Criar preferência de pagamento no Mercado Pago
      payment_service = MercadoPagoService.new
      payment_result = payment_service.create_additional_plan_payment(
        user: current_user,
        transaction: transaction,
        price: @price
      )
      
      if payment_result[:success]
        # Redirecionar para a página de pagamento do Mercado Pago
        redirect_to payment_result[:payment_url], allow_other_host: true
      else
        flash[:alert] = "Erro ao processar pagamento: #{payment_result[:error]}"
        redirect_to new_additional_plan_path
      end
    else
      flash[:alert] = "Não foi possível criar a transação"
      redirect_to new_additional_plan_path
    end
  end
  
  def success
    # Página de sucesso após o pagamento
    @title = "Pagamento Aprovado - NutriPlan"
    @transaction = current_user.transactions.find_by(id: params[:external_reference])
    
    # Adicionar o plano adicional ao usuário se a transação existir
    if @transaction && @transaction.transaction_type == 'additional_plan'
      current_user.add_additional_food_plans(1)
      @transaction.update(status: 'approved') unless @transaction.approved?
    end
  end
  
  def pending
    # Página de pagamento pendente
    @title = "Pagamento Pendente - NutriPlan"
  end
  
  def failure
    # Página de falha no pagamento
    @title = "Pagamento Não Aprovado - NutriPlan"
  end
  
  private
  
  def set_price
    @price = 9.90 # Preço fixo para um plano adicional
  end
end
