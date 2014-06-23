class Budget < ActiveRecord::Base
  unloadable

  belongs_to :project, inverse_of: :budget

  delegate :wages, to: :project

  # Define #income_wages, #cost_wages methods.
  Wage::TYPES.each do |type, value|
    delegate "#{type.to_s}_wages", to: :wages
  end

  delegate :planned_hours_count, to: :calculator
  delegate :planned_income, to: :calculator
  delegate :planned_cost, to: :calculator
  delegate :planned_profit, to: :calculator
  delegate :worked_hours_count, to: :calculator
  delegate :worked_income, to: :calculator
  delegate :worked_cost, to: :calculator
  delegate :worked_profit, to: :calculator

  private
    def calculator
      @calculator ||= BudgetCalculator.new(self)
    end
end
