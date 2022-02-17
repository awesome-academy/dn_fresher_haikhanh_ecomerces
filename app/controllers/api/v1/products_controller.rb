class Api::V1::ProductsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_product, only: %i(show update destroy)

  def index
    @products = Product.includes(:category)
    render json: @products, status: :ok
  end

  def show
    render json: @product, status: :ok
  end

  def create
    product = Product.new product_params
    return unless product.save

    render json: product, status: :created
  end

  def update
    return unless @product.update product_params

    render json: @product, status: :ok
  end

  def destroy
    return unless @product.destroy

    head :no_content
  end

  private

  def find_product
    @product = Product.find_by id: params[:id]
    return if @product

    render json: {message: t(".not_found")}, status: :not_found
  end

  def product_params
    params.require(:product).permit(Product::PRO_ATS)
  end
end
