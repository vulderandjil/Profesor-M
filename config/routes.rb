Rails.application.routes.draw do
  resources :topics do
    resources :chat_sessions, only: [:create, :show]
  end
  
  resources :chat_sessions do
    resources :messages, only: [:create]
  end
  
  root "topics#index"
end