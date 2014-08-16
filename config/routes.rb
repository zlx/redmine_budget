get 'projects/:project_id/budget' => 'budget#show', as: :project_budget
get 'projects/:project_id/budget/settings' => 'budget#edit', as: :edit_project_budget
post 'projects/:project_id/budget/settings' => 'budget#update'

resources :project do
  resources :budget_entries_categories, path: "budget/categories"
end
