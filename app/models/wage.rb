class Wage < ActiveRecord::Base
  unloadable

  # #type is enum-like field
  TYPES = {
    :income_wage => 1,
    :cost_wage => 2
  }

  self.inheritance_column = nil

  belongs_to :project, inverse_of: :project_role_budgets
  belongs_to :role, inverse_of: :project_role_budgets

  validates_presence_of :project, :role, :price_per_hour, :type
  validates_inclusion_of :type, :in => TYPES.values
  validates_numericality_of :price_per_hour, inclusion: { greater_than: 0 }
  validate :assert_start_date_is_before_end_date
  validate :assert_date_doesnt_intercept_other_wages

  # Define #income_wages, #cost_wages scopes
  TYPES.keys.each do |type|
    scope type.to_s.pluralize, -> { where(type: TYPES[type]) }
  end

  # Gets all wages for given project, grouped by user_id and ordered by date.
  def self.get_project_wages(project, wages_type)
    rows = self.connection.select_all """
      SELECT
        wages.id AS wage_id,
        roles.id AS role_id,
        members.user_id AS user_id,
        wages.price_per_hour AS price_per_hour,
        COALESCE(wages.start_date, :project_start_date) AS start_date,
        COALESCE(wages.end_date, :project_end_date) AS end_date

      FROM roles

      INNER JOIN members
        ON  members.project_id = :project_id

      INNER JOIN member_roles
        ON  member_roles.member_id = members.id
        AND member_roles.role_id = roles.id

      INNER JOIN wages AS wages
        ON  wages.role_id = roles.id
        AND wages.project_id = :project_id
        AND wages.type = :wages_type

      ORDER BY start_date ASC, end_date ASC
    """.gsub(/:[A-z\_]+/, {
      ":project_id" => project.id,
      ":project_start_date" => "\"#{project.start_date}\"",
      ":project_end_date" => "\"#{project.end_date}\"",
      ":wages_type" => wages_type,
    })
    rows.each do |row|
      row['start_date'] = Date.parse row['start_date']
      row['end_date'] = Date.parse row['end_date']
    end.group_by do |row|
      row['user_id']
    end
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
      similar_wage = Wage.where(project_id: project_id, role_id: role_id, type: type).where("wages.id != ?", id.to_i)
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
