class Budget < ActiveRecord::Base
  include Redmine::SafeAttributes
  include Redmine::Utils::DateCalculation
  
  unloadable

  belongs_to :project, inverse_of: :budget

  validates_numericality_of :warning_percent_threshold, allow_nil: true, inclusion: { greater_than: 0 }, only_integer: true

  safe_attributes "working_hours_start", "working_hours_end"

  # Define #wages, #income_wages, #cost_wages methods.
  delegate :wages, to: :project
  Wage::TYPES.each do |type, value|
    delegate "#{type.to_s}_wages", to: :wages
  end

  delegate :planned_hours_count, to: :calculator

  delegate :real_hours_count, to: :calculator
  delegate :real_hours_income, to: :calculator
  delegate :real_hours_cost, to: :calculator
  delegate :real_hours_profit, to: :calculator
  delegate :real_entries_income, to: :calculator
  delegate :real_entries_cost, to: :calculator
  delegate :real_entries_profit, to: :calculator
  delegate :real_income, to: :calculator
  delegate :real_cost, to: :calculator
  delegate :real_profit, to: :calculator

  delegate :total_hours_count, to: :calculator
  delegate :total_hours_income, to: :calculator
  delegate :total_hours_cost, to: :calculator
  delegate :total_hours_profit, to: :calculator
  delegate :total_entries_income, to: :calculator
  delegate :total_entries_cost, to: :calculator
  delegate :total_entries_profit, to: :calculator
  delegate :total_income, to: :calculator
  delegate :total_cost, to: :calculator
  delegate :total_profit, to: :calculator

  def working_days
    (1..7).to_a - non_working_week_days
  end

  def used_costs_percentage
    (real_cost.to_f / total_cost * 100).round
  end

  def should_warn_about_threshold?
    warning_percent_threshold.to_i > 0 && used_costs_percentage >= warning_percent_threshold
  end

  def warn_about_threshold
    unless warned_at && warned_at + 1.day > Date.today
      if should_warn_about_threshold?
        warn_about_threshold!
        self.warned_at = Time.now
        self.save!
      end
    end    
  end

  # Send a warning about budget's usage of resources.
  def warn_about_threshold!
    Mailer.budget_threshold_warning(self).deliver
  end

  # Members of this project, that can :manage_budget
  def users_with_manage_budget_permission
    project.members.select do |member|
      member.roles.map(&:permissions).flatten.include? :manage_budget
    end.map(&:user)
  end

  private

    def calculator
      @calculator ||= BudgetCalculator.new(self)
    end
end
