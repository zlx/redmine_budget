module EspeoBudget::Models::RolePatch
  def self.included(base)
    base.extend         ClassMethods
    base.send :include, InstanceMethods

    base.class_eval do
      has_many :project_role_budgets, inverse_of: :role, :dependent => :delete_all
      has_many :time_entries, inverse_of: :role, :dependent => :delete_all
      has_many :wages, inverse_of: :role, :dependent => :delete_all
    end
  end
  
  module ClassMethods
    
  end
  
  module InstanceMethods
    
  end
end

Rails.application.config.to_prepare do
  Role.send :include, EspeoBudget::Models::RolePatch
end
