module ApplicationHelper
  include Pagy::Frontend
  def full_title page_title = ""
    base_title = t "static_pages.title"
    page_title.empty? ? base_title : "#{page_title} | #{base_title}"
  end

  def show_image product
    if product.image.attached?
      product.image
    else
      "products/default.png"
    end
  end

  def count_current_cart
    current_cart.count
  end
end
