class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :quantity, :description
  belongs_to :category
  has_many :order_details, dependent: :destroy
end
