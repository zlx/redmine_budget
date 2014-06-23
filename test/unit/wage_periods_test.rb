require File.expand_path('../../test_helper', __FILE__)

class WagePeriodsTest < ActiveSupport::TestCase
  fixtures :users, :projects, :roles, :wages

  def setup
    @user = User.first
    @project = Project.first
    @project.wages.delete_all
    @role = Role.find(1)
    @member = Member.create! user: @user, project: @project, roles: [@role]
    @budget = Budget.create! project: @project

    Wage.create! [
      {
        project: @project,
        type: Wage::TYPES[:income],
        price_per_hour: 10,
        role: @role
      },
      {
        project: @project,
        type: Wage::TYPES[:income],
        price_per_hour: 30,
        role: @role,
        start_date: Date.tomorrow
      },
      {
        project: @project,
        type: Wage::TYPES[:income],
        price_per_hour: 20,
        role: @role,
        end_date: Date.yesterday
      }
    ]

    Project.any_instance.stubs(:custom_start_date).returns 1.month.ago.to_date
    Project.any_instance.stubs(:custom_end_date).returns 1.month.from_now.to_date
    
    WagePeriod.generate_for_project(@project)
  end

  test '#generate_for_project generates all needed MaxWages' do
    max_wages = WagePeriod.all

    assert_equal 3, max_wages.count

    assert_equal @project.custom_start_date,    max_wages[0].start_date
    assert_equal Date.yesterday,         max_wages[0].end_date
    assert_equal 20,                     max_wages[0].income_per_hour

    assert_equal Date.today,     max_wages[1].start_date
    assert_equal Date.today,     max_wages[1].end_date
    assert_equal 10,             max_wages[1].income_per_hour

    assert_equal Date.tomorrow,          max_wages[2].start_date
    assert_equal @project.custom_end_date,      max_wages[2].end_date
    assert_equal 30,                     max_wages[2].income_per_hour
  end
end
