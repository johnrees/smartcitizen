Rails.application.routes.draw do

  # use_doorkeeper
  get "/404" => "errors#not_found"
  get "/500" => "errors#exception"

  api_version(module: "V0", path: {value: "v0"}, default: true) do
    # devices
    resources :devices do
      resources :readings, only: :index
      get 'world_map', on: :collection
    end
    # readings
    resources :readings, only: [:create]
    match "add" => "readings#add", via: [:get, :post, :patch, :put]
    # sensors
    resources :sensors, only: [:index, :show, :create]
    # components
    resources :components, only: :index
    # kits
    resources :kits, only: [:index, :show]
    # users
      resources :users, only: [:index, :show, :create]
      # password_resets
      resources :password_resets, only: [:create, :update]
      # me
      resources :me, only: [:index] do
        patch '/' => 'me#update', on: :collection
      end
    # home
    root to: 'static#home'
  end

end
