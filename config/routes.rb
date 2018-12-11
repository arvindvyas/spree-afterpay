Spree::Core::Engine.add_routes do
  post '/afterpay', to: 'afterpay#create_order', as: :afterpay_create_order
  get '/afterpay/confirm', to: 'afterpay#confirm', as: :confirm_afterpay
  get '/afterpay/cancel', to: 'afterpay#cancel', as: :cancel_afterpay
  get '/afterpay/notify', to: 'afterpay#notify', as: :notify_afterpay

  namespace :admin do
    # Using :only here so it doesn't redraw those routes
    resources :orders, only: [] do
      resources :payments, only: [] do
        member do
          get 'afterpay_refund'
          post 'afterpay_refund'
        end
      end
    end
  end
end
