require File.expand_path('../../test_helper', __FILE__)

class BudgetCalculatorTest < ActiveSupport::TestCase
  fixtures :projects, :roles, :wages, :users

  def setup
    @user = User.first
    @project = Project.first
    @project.wages.delete_all
    @role = Role.find(1)
    @cheaper_role = Role.find(2)
    @member = Member.create! user: @user, project: @project, roles: [@role, @cheaper_role]
    @budget = Budget.create! project: @project
    @activity = TimeEntryActivity.create! project: @project, name: 'test'

    Project.any_instance.stubs(:custom_start_date).returns 1.month.ago.to_date
    Project.any_instance.stubs(:custom_end_date).returns 1.month.from_now.to_date

    ProjectRoleBudget.create! [
      {
        project: @project,
        role: @role,
        hours_count: 100
      }
    ]

    Wage.create! [
      {
        project: @project,
        type: Wage::TYPES[:income],
        price_per_hour: 20,
        role: @role,
        end_date: Date.yesterday
      },
      {
        project: @project,
        type: Wage::TYPES[:income],
        price_per_hour: 10,
        role: @cheaper_role
      },
      {
        project: @project,
        type: Wage::TYPES[:cost],
        price_per_hour: 5,
        role: @cheaper_role
      },
      {
        project: @project,
        type: Wage::TYPES[:income],
        price_per_hour: 30,
        role: @role,
        start_date: Date.today
      }
    ]

    TimeEntry.create! [
      {
        user: @user,
        role: @role,
        project: @project,
        activity: @activity,
        hours: 20.5,
        spent_on: Date.yesterday,
      },
      {
        user: @user,
        role: @cheaper_role,
        project: @project,
        activity: @activity,
        hours: 10,
        spent_on: Date.today,
      },
      {
        user: @user,
        role: @role,
        project: @project,
        activity: @activity,
        hours: 30,
        spent_on: Date.tomorrow,
      }
    ]

    WagePeriod.generate_for_project(@project)
  end

  test "WagePeriods are generated correctly" do
    periods = WagePeriod.all

    assert_equal 3, periods.count
  end

  test 'counts correctly all attributes and returns correct #works_by_role rows also' do
    calc = BudgetCalculator.new(@budget)

    assert_equal 20.5 + 10 + 30, calc.real_hours_count
    assert_equal 20.5 * 20 + 10 * 10 + 30 * 30, calc.real_income
    assert_equal 10 * 5, calc.real_cost
    assert_equal calc.real_income - calc.real_cost, calc.real_profit

    row = calc.works_by_role.find { |r| r[:role] == @role }

    assert_equal 100, row[:planned_hours_count]
    assert_equal 30, row[:planned_income_per_hour]
    assert_equal 0, row[:planned_cost_per_hour]

    assert_equal 49.5, row[:remaining_hours_count]
    assert_equal row[:remaining_hours_count] * row[:planned_income_per_hour], row[:remaining_income]
    assert_equal row[:remaining_hours_count] * row[:planned_cost_per_hour], row[:remaining_cost]
    assert_equal row[:remaining_income] - row[:remaining_cost], row[:remaining_profit]

    assert_equal row[:real_income] + row[:remaining_income], row[:total_income]
    assert_equal row[:real_cost] + row[:remaining_cost], row[:total_cost]
    assert_equal row[:real_profit] + row[:remaining_profit], row[:total_profit]
  end
end
