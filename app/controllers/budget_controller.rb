class BudgetController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize

  def show
    current_date = params[:current_date] ? Date.parse(params[:current_date]) : Date.today
    @budget_calculator = BudgetCalculator.new(@budget, current_date)
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
end
