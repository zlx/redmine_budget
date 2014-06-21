require 'models/project_patch_1'
require 'models/role_patch_1'

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
  
  menu :project_menu, :budget, { :controller => 'budget', :action => 'show' }, :caption => 'Budget', param: :project_id
end
