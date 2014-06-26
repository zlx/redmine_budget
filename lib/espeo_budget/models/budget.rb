require_dependency "espeo_budget/models/wage"

class Budget < ActiveRecord::Base
  unloadable

  belongs_to :project, inverse_of: :budget

  validates_numericality_of :warning_percent_threshold, allow_nil: true, inclusion: { greater_than: 0 }, only_integer: true

  # Define #wages, #income_wages, #cost_wages methods.
  delegate :wages, to: :project
  Wage::TYPES.each do |type, value|
    delegate "#{type.to_s}_wages", to: :wages
  end

  delegate :planned_hours_count, to: :calculator
  delegate :worked_hours_count, to: :calculator
  delegate :worked_income, to: :calculator
  delegate :worked_cost, to: :calculator
  delegate :worked_profit, to: :calculator
  delegate :total_income, to: :calculator
  delegate :total_cost, to: :calculator
  delegate :total_profit, to: :calculator

  def used_costs_percentage
    (worked_cost.to_f / total_cost * 100).round
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
  def managing_users
    project.members.select do |member|
      member.roles.map(&:permissions).flatten.include? :manage_budget
    end.map(&:user)
  end

  private

    def calculator
      @calculator ||= BudgetCalculator.new(self)
    end
end
