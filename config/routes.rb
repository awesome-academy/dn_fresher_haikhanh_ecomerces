Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :products
    end
  end

  scope "(:locale)", locale: /en|vi/ do
    root "static_pages#home"
    get "/home", to: "static_pages#home"

    devise_for :users

    resources :carts, except: %i(show new edit) do
      collection do
        get "delete-all", to: "carts#destroy_all"
      end
    end

    resources :orders, only: %i(new create) do
      collection do
        get "new", to: "orders#new"
        post "new", to: "orders#create"
      end
    end


    resources :products, only: %i(index show)
    namespace :admin do
      root "static_pages#home"
      get "/home", to: "static_pages#home"
      delete "/logout", to: "static_pages#destroy"
      resources :products
      resources :users
      scope :orders do
        resource :bulk_order do
          delete "delete", to: "bulk_orders#delete"
          patch "restore", to: "bulk_orders#restore"
        end
      end
      resources :orders do
        resources :order_details, only: :index
        collection do
          get "trash", to: "orders#trash"
        end
        member do
          delete "delete", to: "orders#delete"
          patch "restore", to: "orders#restore"
        end
      end
    end
  end
end
