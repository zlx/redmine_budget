class Wage < ActiveRecord::Base
  unloadable

  # #type is enum-like field
  TYPES = {
    :client_wage => 1,
    :cost_wage => 2
  }

  self.inheritance_column = nil

  belongs_to :project, inverse_of: :project_role_budgets
  belongs_to :role, inverse_of: :project_role_budgets

  validates_presence_of :project, :role, :price, :type
  validates_inclusion_of :type, :in => TYPES.values
  validates_numericality_of :price, inclusion: { greater_than: 0 }
  validate :assert_start_date_is_before_end_date
  validate :assert_date_doesnt_intercept_other_wages

  # Define #client_wages, #cost_wages scopes
  TYPES.keys.each do |type|
    scope type.to_s.pluralize, -> { where(type: TYPES[type]) }
  end

  def real_start_date
    start_date || (project.start_date if project)
  end

  def real_end_date
    end_date || (project.end_date if project)
  end

  private
    def assert_date_fits_project_date
      %i[start_date end_date].each do |column|
        if self.send(column) && !self.send(column).between?(project.start_date, project.end_date)
          errors.add(column, "must be between project's start and end date.")
        end
      end
    end

    def assert_start_date_is_before_end_date
      if start_date && end_date && start_date > end_date 
        errors.add(:end_date, "must be after start date.")
      end
    end

    def assert_date_doesnt_intercept_other_wages
      similar_wage = Wage.where(project_id: project_id, role_id: role_id).where("wages.id != ?", id.to_i)
      if similar_wage.where("""
          COALESCE(wages.start_date, :project_start_date) BETWEEN :start_date AND :end_date
          OR COALESCE(wages.end_date, :project_end_date) BETWEEN :start_date AND :end_date
          OR (COALESCE(wages.start_date, :project_start_date) < :start_date AND COALESCE(wages.end_date, :project_end_date) > :end_date)
        """, {
          project_start_date: (project.start_date if project),
          project_end_date: (project.end_date if project),
          start_date: real_start_date,
          end_date: real_end_date
        }).exists?
        errors.add(:base, "There is already a wage in this date period. Select another start or end date.")
      end
    end
end
