class BudgetForm
  unloadable

  attr_reader :budget, :params, :error

  def initialize(budget, params)
    @budget = budget
    @params = params
  end

  def save
    begin
      Wage.transaction do
        ## ProjectRoleBudgets
        params['project_role_budgets'] = params['project_role_budgets'].values
          .select { |x| x['role_id'] && x['hours_count'].to_i > 0 }

        existing_ids = params['project_role_budgets'].map { |x| x['id'] }

        # Remove IDs that no more exist
        budget.project.project_role_budgets.where("id NOT IN (?)", existing_ids).destroy_all

        # Update/create existing rows
        params['project_role_budgets'].each do |row_params|
          project_role_budget = if row_params['id'].to_i > 0
            budget.project.project_role_budgets.find_or_initialize_by_id(row_params['id'])
          else
            budget.project.project_role_budgets.new
          end

          project_role_budget.attributes = row_params.slice(*%w[role_id hours_count])
          project_role_budget.save!
        end

        ## Wages
        params['wages'] = params['wages'].values
          .select { |x| x['role_id'] && x['price'].to_i > 0 }

        existing_ids = params['wages'].map { |x| x['id'] }

        # Remove IDs that no more exist
        budget.project.wages.where("id NOT IN (?)", existing_ids).destroy_all

        # Update/create existing rows
        params['wages'].each do |row_params|
          wage = if row_params['id'].to_i > 0
            budget.project.wages.find_or_initialize_by_id(row_params['id'])
          else
            budget.project.wages.new
          end

          wage.attributes = row_params.slice(*%w[role_id type price start_date end_date])
          wage.save!
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      @error = e.message
      false
    end
  end
end
