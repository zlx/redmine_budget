class BudgetController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize
  accept_api_auth :show, :raport

  helper :custom_fields

  def show
    @budget_calculator = BudgetCalculator.new(@budget, budget_params)

    respond_to do |format|
      format.html
      format.api
    end
  end

  def raport
    @budget_calculator = BudgetCalculator.new(@budget, budget_params)

    wages_type = params[:wages_type] || "cost"
    budget_entries_type = params[:budget_entries_type] || "cost"
    @raport = BudgetRaport.new(@budget_calculator, wages_type, budget_entries_type)

    respond_to do |format|
      format.html
      format.api
      format.csv do
        csv_string = FCSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
          @raport.to_table.each do |row|
            csv << row
          end
        end

        send_data(csv_string, {
          type: 'text/csv; header=present', 
          filename: "budget-raport-#{@raport.wages_type.pluralize}-#{@project.identifier}-#{@raport.start_date}-#{@raport.end_date}.csv"
        })
      end
    end
  end

  def edit
    @roles = Role.sorted
    @form = BudgetForm.new(@budget, params[:budget])
    @budget_calculator = BudgetCalculator.new(@budget)
  end

  def update
    edit

    if @form.save
      redirect_to edit_project_budget_path(@project), notice: l(:notice_successful_update)
    else
      flash.now[:error] = @form.error.message if @form.error
      render :edit
    end
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
      redirect_to @project, flash: { error: l(:error_custom_project_dates_are_required) } unless @project.custom_start_date && @project.custom_end_date
      
      @budget = Budget.where(project_id: @project.id).first_or_create!
    end

    def budget_params
      budget_params = {}
      begin
        budget_params[:start_date] = Date.parse(params[:start_date]) if params[:start_date].present?
        budget_params[:end_date] = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today
      rescue ArgumentError => e
      end
      budget_params
    end
end
