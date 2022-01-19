module SessionsHelper
  def log_in user
    session[:user_id] = user.id
    session[:user_name] = user.name
  end

  def current_user
    @current_user ||= User.find_by id: session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def redirect_back_or default
    redirect_to session[:forwarding_url] || default
    session.delete(:forwarding_url)
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end

  def log_out
    session.delete :user_id
    session.delete :user_name
    @current_user = nil
  end

  def add_to_cart product_id, quantity
    quantity_card = current_cart[product_id.to_s] || 0
    quantity_card += quantity.to_i
    current_cart[product_id.to_s] = quantity_card
  end

  def current_cart
    @current_cart ||= session[:cart]
  end

  def load_product_in_cart
    cart_items = []
    current_cart.each do |id, quantity|
      product = Product.find_by id: id
      if product
        cart_items << {product: product, quantity_order: quantity,
                       total_price_item: quantity * product[:price]}
      else
        current_cart.delete id
      end
    end
    cart_items
  end

  def total_price_cart cart_items
    cart_items.reduce(0) do |total, item|
      total + item[:total_price_item]
    end
  end
end
