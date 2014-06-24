module EspeoBudget::Models::TimeEntryPatch
  def self.included(base)
    base.extend         ClassMethods
    base.send :include, InstanceMethods

    base.class_eval do
      belongs_to :role, inverse_of: :time_entries
      validates_presence_of :role_id

      safe_attributes "role_id"
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
  end
end

Rails.application.config.to_prepare do
  TimeEntry.send :include, EspeoBudget::Models::TimeEntryPatch
end
