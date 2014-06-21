class Budget < ActiveRecord::Base
  unloadable

  belongs_to :project, inverse_of: :budget

  delegate :wages, to: :project

  # Define #income_wages, #cost_wages methods.
  Wage::TYPES.each do |type, value|
    delegate type.to_s.pluralize, to: :wages
  end

  def planned_hours_count
    project.project_role_budgets.pluck(:hours_count).reduce(&:+).to_i
  end

  def planned_income
    @planned_income ||= planned_wages_price_sum(income_wages)
  end

  def planned_cost
    @planned_cost ||= planned_wages_price_sum(cost_wages)
  end

  def planned_profit
    @planned_profit ||= planned_income - planned_cost
  end

  private

    def planned_wages_price_sum(given_wages)
      wages = given_wages.order("start_date ASC, end_date ASC").to_a
      project.project_role_budgets.reduce(0) do |sum, role_budget|
        wages = wages.select { |wage| wage.role_id == role_budget.role_id }
        return sum unless wages.present?
        wage = wages.find { |w| Date.today.between?(w.real_start_date, w.real_end_date) } || (wages.last if Date.today > wages.last.end_date) || wages.first

        sum + role_budget.hours_count * wage.price_per_hour
      end
    end
end
