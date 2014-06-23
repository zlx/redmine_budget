class BudgetView
  unloadable

  attr_reader :budget, :current_date

  def initialize(budget, current_date = Date.today)
    @budget = budget
    @current_date = current_date

    Rails.cache.fetch(budget.project) do
      WagePeriod.generate_for_project(budget.project)
      true
    end
  end

  def cache_key
    [budget.project.cache_key, budget.cache_key, current_date]
  end

  def roles_work
    sql = """
      SELECT
        wp.role_id,
        (wp.cost_per_hour * SUM(te.hours)) cost,
        (wp.income_per_hour * SUM(te.hours)) income,
        SUM(te.hours) hours_count

      FROM wage_periods wp

      LEFT JOIN time_entries te
        ON te.user_id = wp.user_id
        AND te.project_id = wp.project_id
        AND te.spent_on BETWEEN wp.start_date AND wp.end_date
        AND te.spent_on <= ':current_date'

      WHERE 
        wp.project_id = :project_id

      GROUP BY wp.id

      HAVING
        hours_count > 0
    """.gsub(/:[A-z\_]+/, {
      ":project_id" => budget.project.id,
      ":current_date" => @current_date
    })

    Role.connection.select_all(sql)
      .group_by { |row| row['role_id'] }
      .map do |role_id, rows|
        {
          role: Role.find(role_id),
          periods: rows,
          total_cost: ( total_cost = rows.map { |x| x['cost'].to_i }.reduce(&:+) ),
          total_income: ( total_income = rows.map { |x| x['income'].to_i }.reduce(&:+) ),
          total_profit: total_cost + total_income,
          total_hours_count: rows.map { |x| x['hours_count'].to_i }.reduce(&:+),
        }
      end
  end

  def users_work
    sql = """
      SELECT
        wp.user_id,
        (wp.cost_per_hour * SUM(te.hours)) cost,
        (wp.income_per_hour * SUM(te.hours)) income,
        SUM(te.hours) hours_count

      FROM wage_periods wp

      LEFT JOIN time_entries te
        ON te.user_id = wp.user_id
        AND te.project_id = wp.project_id
        AND te.spent_on BETWEEN wp.start_date AND wp.end_date
        AND te.spent_on <= ':current_date'

      WHERE 
        wp.project_id = :project_id

      GROUP BY wp.id

      HAVING
        hours_count > 0
    """.gsub(/:[A-z\_]+/, {
      ":project_id" => budget.project.id,
      ":current_date" => @current_date
    })

    User.connection.select_all(sql)
      .group_by { |row| row['user_id'] }
      .map do |user_id, rows|
        {
          user: User.find(user_id),
          periods: rows,
          total_cost: ( total_cost = rows.map { |x| x['cost'].to_i }.reduce(&:+) ),
          total_income: ( total_income = rows.map { |x| x['income'].to_i }.reduce(&:+) ),
          total_profit: total_cost + total_income,
          total_hours_count: rows.map { |x| x['hours_count'].to_i }.reduce(&:+),
        }
      end
  end
end
