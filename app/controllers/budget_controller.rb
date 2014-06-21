class BudgetController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize

  def show
    current_date = params[:current_date] ? Date.parse(params[:current_date]) : Date.today
    @budget_view = BudgetView.new(@budget, current_date)
  end

  def edit
    @roles = Role.sorted
    @form = BudgetForm.new(@budget, params[:budget])
  end

  def update
    edit
    if @form.save
      redirect_to edit_project_budget_path(@project), notice: l(:notice_successful_update)
      # @form = BudgetForm.new(@budget)
      # render :edit
    else
      flash.now[:error] = @form.error.message if @form.error
      render :edit
    end
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
      @budget = Budget.first_or_initialize(project: @project)
    end
end
