# This is a "helper table" which is generated from `wages` table.
# It's only for the usage of BudgetView.
# 
# For given #project and #user, we can get all date periods (start_date <-> end_date),
# with the maximum #cost_per_hour and #income_per_hour for given user
# (maximum: because he can have multiple roles at once at given project
#           if that happens, and every role has some wage at given date period,
#           we'll choose the wage with maximum #price_per_hour).
class WagePeriod < ActiveRecord::Base
  unloadable

  belongs_to :project, inverse_of: :wage_periods
  belongs_to :user
  validates_presence_of :project_id, :user_id, :start_date, :end_date

  def self.generate_for_project(project)
    income_wages = Wage.get_project_wages(project, Wage::TYPES[:income_wage])
    cost_wages = Wage.get_project_wages(project, Wage::TYPES[:cost_wage])

    wage_periods = (income_wages.keys + cost_wages.keys).uniq.map do |user_id|
      user_income_wages = income_wages[user_id] || []
      user_cost_wages = cost_wages[user_id] || []

      # Generate all possible start_date <-> end_date periods
      start_dates = (user_income_wages + user_cost_wages).map { |row| row['start_date'] }
      end_dates = (user_income_wages + user_cost_wages).map { |row| row['end_date'] }
      date_periods = (start_dates + end_dates).uniq.sort
      date_periods = date_periods.each_cons(2).each_with_index.map do |(start_date, end_date), i|
        # For every [X, Y] period, create [X, (Y-1)] and [Y, Y] periods.
        [
          [(i > 0 ? start_date + 1.day : start_date), (end_date - 1.day)],
          [end_date, end_date]
        ]
      end.flatten(1)

      # Now, for every combination of start_date <-> end_date of cost_wages/income_wages,
      # create a WagePeriod.
      date_periods.map do |(start_date, end_date)|
        next if end_date < start_date

        period_income_wage = user_income_wages.select do |wage|
          start_date.between?(wage['start_date'], wage['end_date']) && end_date.between?(wage['start_date'], wage['end_date'])
        end.sort_by do |wage|
          wage['price_per_hour']
        end.last

        period_cost_wage = user_cost_wages.select do |wage|
          start_date.between?(wage['start_date'], wage['end_date']) && end_date.between?(wage['start_date'], wage['end_date'])
        end.sort_by do |wage|
          wage['price_per_hour']
        end.last

        next if !period_income_wage && !period_cost_wage

        WagePeriod.new(
          project_id: project.id,
          user_id: user_id,
          role_id: (period_income_wage['role_id'] if period_income_wage) || (period_cost_wage['role_id'] if period_cost_wage),
          cost_per_hour: (period_cost_wage['price_per_hour'] if period_cost_wage) || 0,
          income_per_hour: (period_income_wage['price_per_hour'] if period_income_wage) || 0,
          start_date: start_date,
          end_date: end_date
        )
      end.compact
    end.flatten

    # Before we save wage_periods, 
    # we can merge some of them when they are the same
    # (that is: when their user_id, cost_per_hour and income_per_hour are identical).
    # If yes, then let's just extend the start_date of one of them and remove the other one.
    wage_periods = wage_periods.each_cons(2).map do |wage_one, wage_two|
      attributes = %w[user_id cost_per_hour income_per_hour]
      if wage_one.attributes.slice(*attributes).values == wage_two.attributes.slice(*attributes).values && (wage_one.end_date + 1.day) == wage_two.start_date
        wage_two.start_date = wage_one.start_date
        wage_one.start_date = wage_one.end_date = nil # mark as removed
        wage_two
      else
        [wage_one, wage_two]
      end
    end.flatten.compact.uniq.select { |wage| !wage.start_date.nil? }

    # Finally, destroy previous wage_periods and save the new ones.
    self.transaction do
      project.wage_periods.delete_all
      wage_periods.each(&:save!)
    end
  end
end
