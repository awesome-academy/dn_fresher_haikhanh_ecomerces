class ProductsController < ApplicationController
  before_action :products_by_categories, :get_categories, :init_ransack,
                only: :index

  def index
    return if params[:q].blank? && params[:category].blank?

    products = if params[:q].present?
                 Product.list_products_by_categories(
                   @q.result.includes(:category)
                 )
               elsif params[:category].present?
                 Product.list_products_by_categories(
                   nil, params[:category]
                 )
               end
    @products = pagy_products_by_category products
  end

  def show
    @product = Product.find_by id: params[:id]
    return if @product

    flash[:danger] = t ".not_found"
    redirect_to products_path
  end

  private

  def filter_params params
    params.slice(:category, :price)
  end

  def filter_product
    filter_params(params).each do |key, value|
      @products = @products.public_send("filter_by_#{key}", value) if value
    end
  end

  def products_by_categories
    @products = Product.list_products_by_categories
  end

  def get_categories
    @categories = Category.where parent_id: nil
  end

  def init_ransack
    @q = Product.ransack params[:q]
  end

  def pagy_products_by_category products
    return [] if products.blank?

    products.each do |h|
      pagy = pagy h[:products], items: Settings.length.per_page_12
      h[:pagy] = pagy[0]
      h[:products] = pagy[1]
    end
  end
end
