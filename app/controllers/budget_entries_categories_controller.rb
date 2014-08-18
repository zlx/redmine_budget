class BudgetEntriesCategoriesController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize

  def index
  end

  def new
    @category = BudgetEntriesCategory.new({
      project: @project
    })
    @category.safe_attributes = params[:category]
  end

  def create
    send :new

    if @category.save
      flash[:notice] = t :budget_entries_category_successful_create
      redirect_to project_budget_entries_categories_path(@project)
    else
      render :action => 'new'
    end
  end

  def edit
    @category = BudgetEntriesCategory.find(params[:id])
    @category.safe_attributes = params[:category]
  end

  def update
    send :edit

    if @category.save
      flash[:notice] = t :budget_entries_category_successful_update
      redirect_to project_budget_entries_categories_path(@project)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @category = BudgetEntriesCategory.find(params[:id])
    @category.destroy

    redirect_back_or_default project_budget_entries_categories_path(@project)
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
      redirect_to @project, flash: { error: l(:error_custom_project_dates_are_required) } unless @project.custom_start_date && @project.custom_end_date
      
      @budget = Budget.where(project_id: @project.id).first_or_create!
    end
end
