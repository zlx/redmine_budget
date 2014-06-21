module ProjectPatch1
  def self.included(base)
    base.extend         ClassMethods
    base.send :include, InstanceMethods

    base.class_eval do
      has_one :budget, inverse_of: :project, dependent: :destroy
      has_many :project_role_budgets, inverse_of: :project, dependent: :delete_all
      has_many :wages, inverse_of: :project, dependent: :delete_all
      has_many :wage_periods, inverse_of: :project, dependent: :delete_all
    end
  end

  module ClassMethods
    
  end
  
  module InstanceMethods
    
  end
end

Rails.application.config.to_prepare do
  Project.send :include, ProjectPatch1
end
