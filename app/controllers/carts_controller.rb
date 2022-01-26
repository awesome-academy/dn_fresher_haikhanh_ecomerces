class CartsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_product, :check_quantity, only: %i(create update)
  before_action :check_product_cart, only: %i(update destroy)

  def index
    @cart_items = load_product_in_cart
    @total_price_cart = total_price_cart @cart_items
  end

  def create
    add_to_cart params[:product_id], params[:quantity]
    flash[:success] = t ".add_success"
    redirect_back_current
  end

  def update
    current_cart[params[:product_id].to_s] = params[:quantity].to_i
    flash[:success] = t ".update_success"
    redirect_back_current
  end

  def destroy
    current_cart.delete params[:product_id]
    flash[:success] = t ".delete_success"
    redirect_to carts_path
  end

  def destroy_all
    session[:cart] = {}
    flash[:success] = t ".delete_success"
    redirect_to carts_path
  end

  private

  def check_quantity
    quantity = params[:quantity].to_i
    quantity += current_cart[params[:product_id]] if check_product_id?
    quantity = params[:quantity].to_i if check_update?
    return if @product.quantity >= quantity

    flash[:danger] = t ".not_enough"
    redirect_back_current
  end

  def check_product_id?
    current_cart[params[:product_id]].present?
  end

  def check_product_cart
    return if current_cart[params[:product_id]].present?

    flash[:danger] = t ".not_found"
    redirect_back_current
  end

  def check_update?
    params[:is_update].present?
  end

  def load_product
    @product = Product.find_by id: params[:product_id]
    return if @product

    flash[:danger] = t ".not_found"
    redirect_to products_path
  end
end
