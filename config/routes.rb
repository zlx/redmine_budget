resources :projects do
  member do
    get 'budget' => 'budget#show'
  end
end
