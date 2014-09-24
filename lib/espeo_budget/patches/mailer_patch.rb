module EspeoBudget::Patches::MailerPatch
  def self.included(base)
    base.extend         ClassMethods
    base.send :include, InstanceMethods
  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    # Send a warning to all members of budget.project (that can :manage_budget),
    # about the budget threshold coming to an end.
    def budget_threshold_warning(budget, to_users)
      redmine_headers 'Project' => budget.project.identifier

      @budget = budget
      @subject = I18n.t :budget_threshold_warning_subject, 
        project_name: budget.project.name,
        percent_threshold: budget.used_costs_percentage

      mail :to => to_users.map(&:mail),
           :subject => @subject
    end
  end
end

Rails.application.config.to_prepare do
  Mailer.send :include, EspeoBudget::Patches::MailerPatch
end
