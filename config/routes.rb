get 'projects/:project_id/budget' => 'budget#show', as: :project_budget
get 'projects/:project_id/budget/settings' => 'budget#edit', as: :edit_project_budget
post 'projects/:project_id/budget/settings' => 'budget#update'
