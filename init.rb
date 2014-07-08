require 'espeo_budget/patches/mailer_patch'
require 'espeo_budget/patches/project_patch'
require 'espeo_budget/patches/role_patch'
require 'espeo_budget/patches/time_entry_patch'
require 'espeo_budget/hooks'

Redmine::Plugin.register :espeo_budget do
  name 'Espeo Budget plugin'
  author 'espeo@jtom.me'
  description 'This is a plugin for Redmine'
  version '1.0.0'
  url 'http://espeo.pl'
  author_url 'http://jtom.me'

  project_module :budget do
    permission :view_budget, :budget => :show
    permission :manage_budget, :budget => [:edit, :update]
  end
  
  menu :project_menu, :budget, { :controller => 'budget', :action => 'show' }, :caption => :label_budget, param: :project_id
end
