class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :price, :quantity, :description
  belongs_to :category
end
