class ProjectRoleBudget < ActiveRecord::Base
  unloadable

  belongs_to :project, inverse_of: :project_role_budgets
  belongs_to :role, inverse_of: :project_role_budgets
  
  validates_presence_of :project, :role, :hours_count
  validates_numericality_of :hours_count, inclusion: { greater_than: 0 }
end
