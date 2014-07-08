module EspeoBudget::Patches::ProjectPatch
  def self.included(base)
    base.extend         ClassMethods
    base.send :include, InstanceMethods

    base.class_eval do
      has_one :budget, inverse_of: :project, dependent: :destroy
      has_many :project_role_budgets, inverse_of: :project, dependent: :delete_all
      has_many :wages, inverse_of: :project, dependent: :delete_all
      has_many :wage_periods, inverse_of: :project, dependent: :delete_all

      after_create :copy_budget_from_parent
    end
  end

  module ClassMethods
    
  end
  
  module InstanceMethods
    def cache_key
      "#{super}/#{updated_on.to_s}"
    end

    def copy_budget_from_parent
      project = self

      if parent
        project.wages = []
        parent.wages.find_each do |row|
          project.wages << Wage.new(row.attributes) do |new_row|
            new_row.project = project
          end
        end

        project.project_role_budgets = []
        parent.project_role_budgets.find_each do |row|
          project.project_role_budgets << ProjectRoleBudget.new(row.attributes) do |new_row|
            new_row.project = project
          end
        end
      end
    end
  end
end

Rails.application.config.to_prepare do
  Project.send :include, EspeoBudget::Patches::ProjectPatch
end
