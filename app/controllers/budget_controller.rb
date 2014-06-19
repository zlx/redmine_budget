class BudgetController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize

  def show
  end

  def edit
    @roles = Role.sorted
  end

  def update
    @form = BudgetForm.new(@budget, params[:budget])
    if @form.save
      redirect_to edit_project_budget_path(@project), notice: l(:notice_successful_update)
    else
      flash.now[:error] = @form.error
      edit
      render :edit
    end
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
      @budget = Budget.new(@project)
    end
end
