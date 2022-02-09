class Admin::ProductsController < Admin::BaseController
  authorize_resource

  before_action :find_product, except: :index

  def index
    @q = Product.ransack params[:q]
    if params[:q].present?
      @pagy, @products = pagy @q.result, items: Settings.length.per_page_5
    else
      @pagy, @products = pagy Product.order_by_name,
                              items: Settings.length.per_page_5
    end
  end

  def show; end

  private
  def find_product
    @product = Product.find_by id: params[:id]
    return if @product

    flash[:danger] = t ".not_found"
    redirect_to admin_products_path
  end
end
