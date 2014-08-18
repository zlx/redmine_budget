class BudgetCalculator
  unloadable

  attr_reader :budget, :start_date, :end_date

  def initialize(budget, params = {})
    @budget = budget
    @start_date = params[:start_date] if params[:start_date].present?
    @end_date = params[:end_date] if params[:end_date].present?
    @start_date ||= budget.project.custom_start_date
    @end_date ||= budget.project.custom_end_date

    Rails.cache.fetch(wage_periods_cache_key) do
      WagePeriod.generate_for_project(budget.project)
      true
    end
  end

  def wage_periods_cache_key
    [budget.project, budget, budget.project.custom_start_date, budget.project.custom_end_date]
  end

  def cache_key
    recent_project_time_entry = budget.project.time_entries.order("time_entries.updated_on DESC").first

    [
      budget.project.cache_key,
      budget.cache_key, 
      start_date, 
      end_date, 
      (recent_project_time_entry.updated_on if recent_project_time_entry)
    ].join("#")
  end

  def planned_hours_count
    @planned_hours_count ||= works_by_role.map{ |r| r[:planned_hours_count] }.reduce(&:+).to_f
  end

  def real_hours_count
    @real_hours_count ||= works_by_role.map{ |r| r[:real_hours_count] }.reduce(&:+).to_f
  end

  def real_hours_income
    @real_hours_income ||= works_by_role.map{ |r| r[:real_income] }.reduce(&:+).to_f
  end

  def real_hours_cost
    @real_hours_cost ||= works_by_role.map{ |r| r[:real_cost] }.reduce(&:+).to_f
  end

  def real_hours_profit
    real_hours_income - real_hours_cost
  end

  def real_entries_income
    budget_entries.joins(:category)
      .where("budget_entries_categories.entry_type = ?", BudgetEntriesCategory::ENTRY_TYPES[:income])
      .real
      .map(&:netto_amount)
      .sum
  end

  def real_entries_cost
    budget_entries.joins(:category)
      .where("budget_entries_categories.entry_type = ?", BudgetEntriesCategory::ENTRY_TYPES[:cost])
      .real
      .map(&:netto_amount)
      .sum
  end

  def real_entries_profit
    real_entries_income - real_entries_cost
  end

  def real_income
    real_hours_income + real_entries_income
  end

  def real_cost
    real_hours_cost + real_entries_cost
  end

  def real_profit
    real_income - real_cost
  end

  def total_hours_count
    @total_hours_count ||= works_by_role.map{ |r| r[:total_hours_count] }.reduce(&:+).to_f
  end

  def total_hours_income
    @total_hours_income ||= works_by_role.map{ |r| r[:total_income] }.reduce(&:+).to_f
  end

  def total_hours_cost
    @total_hours_cost ||= works_by_role.map{ |r| r[:total_cost] }.reduce(&:+).to_f
  end

  def total_hours_profit
    total_hours_income - total_hours_cost
  end

  def total_entries_income
    budget_entries.joins(:category)
      .where("budget_entries_categories.entry_type = ?", BudgetEntriesCategory::ENTRY_TYPES[:income])
      .map(&:netto_amount)
      .sum
  end

  def total_entries_cost
    budget_entries.joins(:category)
      .where("budget_entries_categories.entry_type = ?", BudgetEntriesCategory::ENTRY_TYPES[:cost])
      .map(&:netto_amount)
      .sum
  end

  def total_entries_profit
    total_entries_income - total_entries_cost
  end

  def total_income
    total_hours_income + total_entries_income
  end

  def total_cost
    total_hours_cost + total_entries_cost
  end

  def total_profit
    total_income - total_cost
  end

  # Get all roles from this budget and their budget statistics.
  def works_by_role
    @works_by_role ||= Role.connection.select_all(get_works_sql(start_date, end_date))
      .group_by { |row| row['role_id'].to_i }
      .map do |role_id, rows|
        planned_work = planned_works_by_role[role_id] || {}

        {
          role: Role.find(role_id),
          periods: rows,

          real_cost: ( real_cost = rows.map { |x| x['cost'].to_f }.reduce(&:+).to_f ),
          real_income: ( real_income = rows.map { |x| x['income'].to_f }.reduce(&:+).to_f ),
          real_profit: ( real_profit = real_income - real_cost ),
          real_hours_count: ( real_hours_count = rows.map { |x| x['hours_count'].to_f }.reduce(&:+).to_f ),

          planned_hours_count: ( planned_hours_count = planned_work[:planned_hours_count].to_f ),
          planned_income_per_hour: ( planned_income_per_hour = planned_work[:planned_income_per_hour].to_f ),
          planned_cost_per_hour: ( planned_cost_per_hour = planned_work[:planned_cost_per_hour].to_f ),

          remaining_hours_count: ( remaining_hours_count = [planned_hours_count - real_hours_count, 0].max ),
          remaining_income: ( remaining_income = remaining_hours_count * planned_income_per_hour ),
          remaining_cost: ( remaining_cost = remaining_hours_count * planned_cost_per_hour ),
          remaining_profit: ( remaining_profit = remaining_income - remaining_cost ),

          total_hours_count: ( real_hours_count + remaining_hours_count ), 
          total_income: ( real_income + remaining_income ), 
          total_cost: ( real_cost + remaining_cost ), 
          total_profit: ( real_profit + remaining_profit ), 
        }
      end
  end

  # Get all users of this project and their budget statistics.
  def works_by_user
    @works_by_user ||= User.connection.select_all(get_works_sql(start_date, end_date))
      .select { |row| row['user_id'].present? }
      .group_by { |row| row['user_id'] }
      .map do |user_id, rows|
        {
          user: User.find(user_id),
          periods: rows,

          real_cost: ( real_cost = rows.map { |x| x['cost'].to_f }.reduce(&:+) ),
          real_income: ( real_income = rows.map { |x| x['income'].to_f }.reduce(&:+) ),
          real_profit: real_income - real_cost,
          real_hours_count: rows.map { |x| x['hours_count'].to_f }.reduce(&:+),
        }
      end
  end

  # Get budget statistics (cost, income, profit) grouped by month.
  # Return value: ["April 2014" => {:cost, :income, :profit}, ...]
  def works_by_month
    Hash[(start_date..end_date).group_by do |date|
      [date.year, date.month].join "-"
    end.values.map(&:first).map do |month_date|
      stat = Role.connection.select_all(get_works_sql(month_date.beginning_of_month, month_date.end_of_month)).reduce({
        cost: 0,
        income: 0,
        profit: 0
      }) do |memo, row|
        memo[:cost] += row['cost'].to_f
        memo[:income] += row['income'].to_f
        memo
      end
      stat[:profit] = stat[:income] - stat[:cost]

      [month_date, stat]
    end]
  end

  def stats_by_month
    stats = works_by_month

    budget_entries.select do |entry|
      !entry.planned?
    end.each do |entry|
      if stat = stats[ entry.created_on.beginning_of_month ]
        if entry.cost?
          stat[:cost] += entry.netto_amount
        elsif entry.income?
          stat[:income] += entry.netto_amount
        end
        
        stat[:profit] = stat[:income] - stat[:cost]
      end
    end

    stats
  end

  def entries_by_category(entry_type)
    budget.project.budget_entries_categories.send(entry_type.pluralize)
  end

  def budget_entries
    budget.project.budget_entries
      .where("budget_entries.created_on BETWEEN ? AND ?", start_date, end_date)
  end

  private

    # For all given roles, get current cost and income wages (for the [start_date, end_date] period).
    # Returns Hash(:role_id => {:role_id, 
    #                           :planned_hours_count, 
    #                           :planned_cost_per_hour, 
    #                           :planned_income_per_hour}).
    def planned_works_by_role
      @planned_works_by_role ||= begin
        all_wages_by_date = budget.project.wages.order("start_date ASC, end_date ASC").to_a

        Hash[budget.project.project_role_budgets.map do |budget|
          row = {
            role_id: budget.role_id,
            planned_hours_count: budget.hours_count
          }

          [:cost, :income].each do |wages_type|
            wages = all_wages_by_date.select { |wage| wage.type == Wage::TYPES[wages_type] && wage.role_id == budget.role_id }

            price_per_hour = if wages.present?
              wage = wages.find { |w| Date.today.between?(w.real_start_date, w.real_end_date) }
              wage ||= (wages.last if Date.today > wages.last.real_start_date)
              wage ||= wages.first
              wage.price_per_hour
            end

            row["planned_#{wages_type}_per_hour".to_sym] = price_per_hour.to_f
          end

          [row[:role_id], row]
        end]
      end
    end

    def get_works_sql(start_date, end_date)
      """
        SELECT
          wp.id wage_period_id,
          te.id time_entry_id,
          wp.role_id,
          te.user_id,
          (wp.cost_per_hour * SUM(te.hours)) cost,
          (wp.income_per_hour * SUM(te.hours)) income,
          SUM(te.hours) hours_count

        FROM wage_periods wp

        LEFT JOIN time_entries te
          ON te.role_id = wp.role_id
          AND te.project_id = wp.project_id
          AND te.spent_on BETWEEN wp.start_date AND wp.end_date
          #{"AND te.spent_on >= ':start_date'" if @start_date}
          #{"AND te.spent_on <= ':end_date'" if @end_date}

        WHERE 
          wp.project_id = :project_id

        GROUP BY wp.id, te.id
      """.gsub(/:[A-z\_]+/, {
        ":project_id" => budget.project_id,
        ":start_date" => start_date,
        ":end_date" => end_date
      })
    end
end
