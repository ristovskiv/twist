class Accounts::PlansController < Accounts::BaseController
  skip_before_action :subscription_required!
  before_action :owner_required!

  def choose
    @plans = Plan.order(:price)
    @client_token = Braintree::ClientToken.generate(
      customer_id: current_account.braintree_customer_id
    )
    render :choose
  end

  def chosen
    if current_account.subscribed?
      update_subscription
    else
      create_subscription
    end
  end

  def cancel
    result = Braintree::Subscription.cancel(current_account.braintree_subscription_id)
    if result.success?
      current_account.update_column(
        :braintree_subscription_status, 
        result.subscription.status
      )
      flash[:notice] = "Your subscription to Twist has been cancelled."
      redirect_to root_url(subdomain: nil)
    end
  end

  private

  def create_subscription
    plan = Plan.find(params[:account][:plan_id])
    result = Braintree::Subscription.create(
      payment_method_nonce: params[:payment_method_nonce],
      plan_id: plan.braintree_id
    )
    if result.success?
      current_account.braintree_subscription_id = result.subscription.id
      current_account.braintree_subscription_status = result.subscription.status
      current_account.plan = plan
      current_account.save
      flash[:notice] = "Your account has been successfully created."
      redirect_to root_url(subdomain: current_account.subdomain)
    else
      flash[:alert] = "Subscription failed: #{result.message}"
      choose
    end
  end

  def update_subscription
    plan = Plan.find(params[:account][:plan_id])
    result = Braintree::Subscription.update(
      current_account.braintree_subscription_id,
      plan_id: plan.braintree_id
    )
    flash[:notice] = "You have changed to the #{plan.name} plan."
    redirect_to root_url(subdomain: current_account.subdomain)
  end
end