require File.expand_path('../../test_helper', __FILE__)

class WageTest < ActiveSupport::TestCase
  fixtures :projects, :roles, :wages

  def wage
    @wage ||= Wage.find(1)
  end

  def test_fixtures_are_created
    assert wage.persisted?
  end

  def test_same_wages_must_be_in_different_dates
    Project.any_instance.stubs(:start_date).returns 20.days.ago.to_date
    Project.any_instance.stubs(:end_date).returns 20.days.from_now.to_date

    wage.start_date = 7.days.ago
    wage.end_date = 7.days.from_now
    wage.save!

    assert !wage_dates_valid?(nil, nil)
    assert wage_dates_valid?(14.days.ago, 10.days.ago)
    assert !wage_dates_valid?(14.days.ago, 7.days.ago)
    assert !wage_dates_valid?(14.days.ago, Date.today)
    assert !wage_dates_valid?(14.days.ago, 7.days.from_now)
    assert !wage_dates_valid?(14.days.ago, 14.days.from_now)
    assert !wage_dates_valid?(0.days.ago, 14.days.from_now)
    assert !wage_dates_valid?(7.days.from_now, 14.days.from_now)
    assert wage_dates_valid?(10.days.from_now, 14.days.from_now)

    wage.start_date = nil
    wage.end_date = 7.days.from_now
    wage.save!

    assert !wage_dates_valid?(nil, 10.days.from_now)
    assert !wage_dates_valid?(Date.today, 10.days.from_now)
    assert wage_dates_valid?(10.days.from_now, 10.days.from_now)
  end

  private

    def wage_dates_valid?(start_date, end_date)
      other_wage = Wage.new( wage.attributes.slice(*%w[project_id role_id type price]) )
      other_wage.start_date = (start_date.to_date if start_date)
      other_wage.end_date = (end_date.to_date if end_date)
      other_wage.valid?
    end
end
