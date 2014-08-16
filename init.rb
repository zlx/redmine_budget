require 'espeo_budget/patches/mailer_patch'
require 'espeo_budget/patches/project_patch'
require 'espeo_budget/patches/role_patch'
require 'espeo_budget/patches/time_entry_patch'
require 'espeo_budget/hooks'

Redmine::Plugin.register :espeo_budget do
  name 'Espeo Budget plugin'
  author 'espeo@jtom.me'
  description 'Plan the budget of your project - plan its\' roles, manhours, costs and incomes, and see it all in a nice summary view!'
  version '1.0.0'
  url 'http://espeo.pl'
  author_url 'http://jtom.me'

  project_module :budget do
    permission :view_budget, :budget => :show
    permission :manage_budget, :budget => [:edit, :update], 
                               :budget_entries_categories => [:index]
  end
  
  menu :project_menu, :budget, { :controller => 'budget', :action => 'show' }, :caption => :label_budget, param: :project_id
end
