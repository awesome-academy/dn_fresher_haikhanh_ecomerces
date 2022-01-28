class OrdersController < ApplicationController
  before_action :logged_in_user, :load_data_order

  def new; end

  def create
    error_messages = handle_data_product_and_quantity_for_cart
    if check_error_messages? error_messages
      @error_messages = error_messages
      return render :new
    end
    ActiveRecord::Base.transaction do
      build_order
      add_order_detail @order
      @order.save!
    end
    current_cart.clear
    flash[:success] = t ".success"
    redirect_to root_path
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = t ".failed"
    redirect_back_current
  end

  private

  def logged_in_user
    return if user_signed_in?

    store_location
    flash[:danger] = t ".please_login"
    redirect_to login_url
  end

  def build_order
    @order = current_user.orders.build address_id: handle_address
  end

  def handle_address
    return params[:address] if params[:add_address_other].nil?

    address = create_address params[:address_other], params[:phone_other]
    address.save!
    address.id
  end

  def create_address address_other, phone_other
    current_user.addresses.build(
      address_detail: address_other,
      phone: phone_other
    )
  end

  def add_order_detail order
    current_cart.each do |product_id, quantity|
      order.order_details.build(
        product_id: product_id.to_i,
        quantity: quantity,
        price: Product.find_by(id: product_id.to_i).price
      )
    end
  end

  def handle_data_product_and_quantity_for_cart
    exist = {}
    invalid_quantity = {}
    current_cart.each do |product_id, quantity|
      product = Product.find_by id: product_id
      if product.nil?
        exist[product_id.to_i] = t ".not_found"
        current_cart.delete id
        continue
      elsif product.quantity <= quantity
        invalid_quantity[product_id.to_i] = (t ".error_message",
                                               product: product.name)
      end
    end
    {exist: exist, invalid_quantity: invalid_quantity}
  end

  def check_error_messages? error_messages
    !error_messages[:exist].empty? || !error_messages[:invalid_quantity].empty?
  end

  def load_data_order
    @cart_items = load_product_in_cart
    @total_price_cart = total_price_cart @cart_items
    @addresses = current_user.addresses.address_order
  end
end
