class ProductsController < ApplicationController
  def index
    @pagy, @products = pagy Product.sort_by_price,
                            items: Settings.length.per_page_12
  end

  def show
    @product = Product.find_by id: params[:id]
    return if @product

    flash[:danger] = t ".not_found"
    redirect_to products_path
  end
end
