# require 'espeo_budget/models/budget'
# require 'espeo_budget/models/project_role_budget'
# require 'espeo_budget/models/wage'
# require 'espeo_budget/models/wage_period'

require 'espeo_budget/models/mailer_patch'
require 'espeo_budget/models/project_patch'
require 'espeo_budget/models/role_patch'
require 'espeo_budget/models/time_entry_patch'
require 'espeo_budget/hooks'

Redmine::Plugin.register :espeo_budget do
  name 'Espeo Budget plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  project_module :budget do
    permission :view_budget, :budget => :show
    permission :manage_budget, :budget => [:edit, :update]
  end
  
  menu :project_menu, :budget, { :controller => 'budget', :action => 'show' }, :caption => :label_budget, param: :project_id
end
