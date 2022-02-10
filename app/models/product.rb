class Product < ApplicationRecord
  belongs_to :category
  has_many :order_details, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_one_attached :image

  validates :name, presence: true
  validates :quantity, presence: true,
             numericality: {only_integer: true,
                            greater_than_or_equal_to: Settings.length.zero}

  scope :order_by_name, ->{order :name}
  scope :sort_by_price, ->{order :price}
  scope :filter_by_category, ->(category_id){where category_id: category_id}

  class << self
    def list_products_by_categories products = nil, category_id = nil
      if products.nil? && category_id.nil?
        categories_has_products_all
      elsif products.present?
        categories_has_products_passing products
      elsif category_id.present?
        category_by_id category_id
      end
    end

    def categories_has_products_all
      categories = Category.where("id IN (?)",
                                  Product.select(:category_id).distinct)
      categories.all.map do |category|
        {
          category: category.name,
          products: category.products.limit(Settings.length.per_page_12)
        }
      end
    end

    def categories_has_products_passing products
      categories = Category.where("id IN (?)",
                                  products.select(:category_id).distinct)
      categories.all.map do |category|
        {
          category: category.name,
          products: category.products.where(id: products.select(:id))
        }
      end
    end

    def category_by_id category_id
      category = Category.find_by id: category_id
      return [] if category.nil?

      [{
        category: category.name,
        products: category.products
      }]
    end
  end
end
