module EspeoBudget::Patches::TimeEntryPatch
  def self.included(base)
    base.extend         ClassMethods
    base.send :include, InstanceMethods

    base.class_eval do
      belongs_to :role, inverse_of: :time_entries
      validate :fill_in_role_if_missing
      validates_presence_of :role_id

      safe_attributes "role_id"
    end
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    def fill_in_role_if_missing
      if role_id.nil?
        member = Member.where(self.attributes.slice("user_id", "project_id")).joins(:roles).first
        if member && member.roles.present?
          self.role_id = member.roles.first.id
        end
      end
    end
  end
end

Rails.application.config.to_prepare do
  TimeEntry.send :include, EspeoBudget::Patches::TimeEntryPatch
end
