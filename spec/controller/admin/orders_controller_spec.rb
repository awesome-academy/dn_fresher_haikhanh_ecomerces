require "rails_helper"
require "shared/share_example_spec.rb"

RSpec.describe Admin::OrdersController, type: :controller do
  let(:admin) {FactoryBot.create :user, role: 1}

  describe "when valid routing" do
    it{should route(:get, "/admin/orders").to(action: :index)}
    it{should route(:get, "/admin/orders/1").to(action: :show, id: 1)}
    it{should route(:patch, "/admin/orders/1").to(action: :update, id: 1)}
    it{should route(:patch, "/admin/orders/3").to(action: :update, id:3)}
    it{should route(:delete, "/admin/orders/1/delete").to(action: :delete, id: 1)}
    it{should route(:get, "/admin/orders/trash").to(action: :trash)}
    it{should route(:delete, "/admin/orders/4").to(action: :destroy, id: 4)}
    it{should route(:patch, "/admin/orders/4/restore").to(action: :restore, id: 4)}
  end

  it_behaves_like "share check current user is admin"

  describe "admin is logged in" do
    before {sign_in admin}

    describe "GET #index" do
      let(:user){FactoryBot.create :user, name: "khanh"}
      let!(:order1){FactoryBot.create :order, status: 1, deleted_at: nil, user: user}
      let!(:order2){FactoryBot.create :order, status: 2, deleted_at: nil, user: user}
      let!(:order3){FactoryBot.create :order, status: 3, deleted_at: Date.current, user: user}
      let!(:order4){FactoryBot.create :order, status: 4, deleted_at: nil, user: user}

      context "with no params" do
        it "return list order newest with not deleted" do
          get :index
          expect(assigns :orders).to eq [order1, order2, order4]
        end
      end

      context "with params" do
        it "return list order with param status" do
          get :index, params: {status: "resolved"}
          expect(assigns :orders).to eq [order2]
        end
        it "return list order with param user name" do
          get :index, params: {user_name: "khanh"}
          expect(assigns :orders).to eq [order1, order2, order4]
        end
      end
    end

    describe "GET #show" do
      let(:order){FactoryBot.create :order, status: 1, deleted_at: nil}
      context "with valid id" do
        it "return order with id" do
          get :show, params: {id: order.id}
          expect(assigns :order).to eq order
        end
      end

      context "with invalid id" do
        before {get :show, params: {id: -1}}
        it "return flash danger" do
          expect(flash[:danger]).to eq I18n.t("admin.orders.show.not_found")
        end
        it "redirect to admin orders path" do
          expect(response).to redirect_to admin_orders_path
        end
      end
    end

    describe "PATCH #update" do
      context "when order not found" do
        before {patch :update, params: {id: -1}}

        it "should display flash when not found" do
          expect(flash[:danger]).to eq I18n.t("admin.orders.update.not_found")
        end

        it "redirect to template order index when not found" do
          expect(response).to redirect_to admin_orders_path
        end
      end

      context "when order found" do
        let!(:order) {FactoryBot.create(:order, status: 0)}
        context "when update success" do
          it "should update status order" do
            patch :update, params: {id: order.id, status: 1}
            expect(flash[:success]).to eq I18n.t("admin.orders.update.update_status_success")
          end

          it "redirect to template order index" do
            patch :update, params: {id: order.id, status: 1}
            expect(response).to redirect_to admin_orders_path
          end
        end

        context "when status update is rejected" do
          let!(:order) {FactoryBot.create(:order, status: 0)}
          let!(:product) {FactoryBot.create(:product, quantity: 8)}
          let!(:order_detail) {FactoryBot.create(:order_detail, order: order, product: product, quantity: 2)}
          it "should update product quantity" do
            patch :update, params: {id: order.id, status: 3}
            product.quantity = product.quantity + order_detail.quantity
            expect(product.quantity).to eq 8
          end
        end

        it_behaves_like "share update order fail", 0, 0
        it_behaves_like "share update order fail", 1, 0
        it_behaves_like "share update order fail", 1, 1
        it_behaves_like "share update order fail", 2, 4
        it_behaves_like "share update order fail", 3, 4
        it_behaves_like "share update order fail", 4, 4
      end
    end

    describe "DELETE #delete" do
      context "when order not found" do
        before {delete :delete, params: {id: -1}}

        it "should display flash when not found" do
          expect(flash[:danger]).to eq I18n.t("admin.orders.delete.not_found")
        end
        it "redirect to template order index when not found" do
          expect(response).to redirect_to admin_orders_path
        end
      end

      context "when order found" do
        let(:order) {FactoryBot.create(:order, status: 0)}
        it "should call format js when delete success" do
          delete :delete, params: {id: order.id, format: :js}
        end
        it "redirect to template order index when delete success" do
          delete :delete, params: {id: order.id}
          expect(response).to redirect_to admin_orders_path
        end
      end
    end

    describe "patch #restore" do
      context "when order not found" do
        before {delete :delete, params: {id: -1}}

        it "should display flash when not found" do
          expect(flash[:danger]).to eq I18n.t("admin.orders.restore.not_found")
        end
        it "redirect to template order index when not found" do
          expect(response).to redirect_to admin_orders_path
        end
      end

      context "when order found" do
        let(:order) {FactoryBot.create(:order, status: 0)}
        it "should call format js when delete success" do
          patch :restore, params: {id: order.id, format: :js}
        end
        it "redirect to template order index when restore success" do
          patch :restore, params: {id: order.id}
          expect(response).to redirect_to trash_admin_orders_path
        end
      end
    end

    describe "GET #trash" do
      let(:user){FactoryBot.create :user, name: "khanh"}
      let!(:order1){FactoryBot.create :order, status: 1, deleted_at: nil, user: user}
      let!(:order2){FactoryBot.create :order, status: 2, deleted_at: nil, user: user}
      let!(:order3){FactoryBot.create :order, status: 3, deleted_at: Date.current, user: user}
      let!(:order4){FactoryBot.create :order, status: 4, deleted_at: Date.current, user: user}

      context "with no params" do
        it "return list order newest with deleted" do
          get :trash
          expect(assigns(:trash_orders)).to eq [order3, order4]
        end
      end

      context "with params" do
        it "return list order with param status" do
          get :trash, params: {status: "rejected"}
          expect(assigns(:trash_orders)).to eq [order3]
        end
        it "return list order with param user name" do
          get :trash, params: {user_name: "khanh"}
          expect(assigns(:trash_orders)).to eq [order3, order4]
        end
      end
    end

    describe "DELETE #destroy" do
      context "when order not found" do
        before {delete :destroy, params: {id: -1}}

        it "should display flash when not found" do
          expect(flash[:danger]).to eq I18n.t("admin.orders.destroy.not_found")
        end

        it "redirect to template order index when not found" do
          expect(response).to redirect_to admin_orders_path
        end
      end

      context "when order found" do
        let(:order) {FactoryBot.create(:order, status: 0)}
        it "should call format js when destroy success" do
          delete :destroy, params: {id: order.id, format: :js}
        end
        it "should display flash when destroy fail" do
          delete :destroy, params: {id: order.id}
          expect(flash[:danger]).to eq I18n.t("admin.orders.destroy.destroy_restore_fail")
        end
      end
    end
  end
end
