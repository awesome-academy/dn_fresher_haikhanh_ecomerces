require "rails_helper"
include SessionsHelper

RSpec.describe CartsController, type: :controller do
  let!(:product) {FactoryBot.create :product}
  let!(:user) {FactoryBot.create :user}
  before(:each) do
    request.env['HTTP_REFERER'] = root_path
  end

  describe "user is log in" do
    before{sign_in user}

    describe "GET #index" do
      before do
        session[:cart] = {}
        current_cart[product.id.to_s] = 2
        @cart_items = load_product_in_cart
        @total_price_cart = total_price_cart @cart_items
        get :index
      end

      it "assigns @cart_items" do
        expect(assigns :cart_items).to eq @cart_items
      end

      it "assigns @total_price_cart" do
        expect(assigns :total_price_cart).to eq @total_price_cart
      end

      it "renders the index template" do
        expect(response).to render_template :index
      end
    end

    describe "POST #create" do
      context "when product exist" do
        before do
          session[:cart] = {}
          post :create, xhr: true, params: {product_id: product.id, quantity: 2}
        end

        it "add to cart succcess" do
          expect(current_cart[product.id.to_s]).to eq 2
        end

        it "has a 200 status code" do
          expect(response).to have_http_status(:ok)
        end

        it "show flash message" do
          expect(flash[:success]).to eq I18n.t("carts.create.add_success")
        end
      end

      context "When the quantity is not enough" do
        before do
          session[:cart] = {}
          post :create, xhr: true, params: {product_id: product.id, quantity: 999}
        end

        it "show flash message" do
          expect(flash[:danger]).to eq I18n.t("carts.create.not_enough")
        end
      end

      context "when product does not exist" do
        before do
          session[:cart] = {}
          post :create, xhr: true, params: {product_id: 0, quantity: 5}
        end

        it "show flash message" do
          expect(flash[:danger]).to eq I18n.t("carts.create.not_found")
        end
      end
    end

    describe "PUT #update" do
      before do
        session[:cart] = {}
        current_cart[product.id.to_s] = 2
      end

      context "when product exist" do
        before do
          put :update, params: {id: 1, product_id: product.id, quantity: 5}
        end

        it "update quantity cart succcess" do
          expect(current_cart[product.id.to_s]).to eq 5
        end

        it "show flash message" do
          expect(flash[:success]).to eq I18n.t("carts.update.update_success")
        end
      end

      context "When the quantity is not enough" do
        before do
          session[:cart] = {}
          put :update, params: {id: 1, product_id: product.id, quantity: 999}
        end

        it "show flash message" do
          expect(flash[:danger]).to eq I18n.t("carts.update.not_enough")
        end
      end

      context "when product does not exist" do
        before do
          put :update, params: {id: 0, product_id: 0, quantity: 5}
        end

        it "show flash message" do
          expect(flash[:danger]).to eq I18n.t("carts.update.not_found")
        end
      end
    end

    describe "DELETE #destroy" do
      before do
        session[:cart] = {}
        current_cart[product.id.to_s] = 2
      end
      context "when product exist" do
        before do
          delete :destroy, params: {id: 1, product_id: product.id}
        end

        it "delete item cart succcess" do
          expect(current_cart[product.id.to_s].nil?).to eq true
        end

        it "show flash message" do
          expect(flash[:success]).to eq I18n.t("carts.destroy.delete_success")
        end

        it "redirect to carts path" do
          expect(response).to redirect_to carts_path
        end
      end

      context "when product does not exist" do
        before do
          delete :destroy, params: {id: 1, product_id: 0}
        end

        it "show flash message" do
          expect(flash[:danger]).to eq I18n.t("carts.update.not_found")
        end
      end
    end

    describe "GET #destroy_all" do
      before do
        session[:cart] = {}
        get :destroy_all
      end

      it "delete items cart succcess" do
        expect(current_cart.empty?).to eq true
      end

      it "redirect to carts path" do
        expect(response).to redirect_to carts_path
      end

      it "show flash message" do
        expect(flash[:success]).to eq I18n.t("carts.destroy_all.delete_success")
      end
    end
  end
end
