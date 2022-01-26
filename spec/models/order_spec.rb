require "rails_helper"

RSpec.describe Order, type: :model do
  subject {FactoryBot.create :order}

  it "is valid" do
    expect(subject).to be_valid
  end

  describe "associations" do
    it {is_expected.to have_many(:order_details).dependent(:destroy)}
    it {is_expected.to belong_to(:user)}
    it {is_expected.to belong_to(:address)}
  end

  describe "scope" do
    let!(:user1){FactoryBot.create :user, name: "khanh"}
    let!(:user2){FactoryBot.create :user, name: "hai"}
    let!(:order1){FactoryBot.create :order, status: 1, deleted_at: nil, user: user1}
    let!(:order2){FactoryBot.create :order, status: 2, deleted_at: nil, user: user2}
    let!(:order3){FactoryBot.create :order, status: 3, deleted_at: Date.current, user: user2}

    it "return list orders recent" do
      orders = Order.recent_orders
      expect(orders.to_a.sort).to eq [order2, order1].sort
    end

    context "search by username" do
      it "return list order with valid name" do
        username = "khanh"
        orders = Order.filter_by_name(username)
        expect(orders).to eq [order1]
      end
      it "return empty list with invalid name" do
        username = "abc"
        orders = Order.filter_by_name(username)
        expect(orders).to eq []
      end
    end

    context "load orders by ids" do
      it "return list order with array of ids" do
        ids = [order1.id, order2.id]
        orders = Order.load_by_ids(ids)
        expect(orders).to eq [order1, order2]
      end
      it "return empty list with empty array of ids" do
        ids = []
        orders = Order.load_by_ids(ids)
        expect(orders).to eq []
      end
    end

    context "load orders with status not rejected or canceled" do
      it "return list orders status not rejected or canceled" do
        orders = Order.not_rejected_canceled
        expect(orders).to eq [order1, order2]
      end
    end

    context "load orders with not_deleted" do
      it "return list orders not_deleted" do
        orders = Order.not_deleted
        expect(orders).to eq [order1, order2]
      end
    end
  end
end
