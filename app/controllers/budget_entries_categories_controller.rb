class BudgetEntriesCategoriesController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize

  def index
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
      redirect_to @project, flash: { error: l(:error_custom_project_dates_are_required) } unless @project.custom_start_date && @project.custom_end_date
      
      @budget = Budget.where(project_id: @project.id).first_or_create!
    end
end
