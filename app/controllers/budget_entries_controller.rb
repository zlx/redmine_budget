class BudgetEntriesController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize
  
  helper :custom_fields
  include CustomFieldsHelper

  def new
    @budget_entry = BudgetEntry.new({
      project: @project,
      user: User.current
    })
    @budget_entry.safe_attributes = params[:budget_entry]

    @budget_entries_categories = @project.budget_entries_categories
    if params[:entry_type]
      @budget_entries_categories = @budget_entries_categories.where(entry_type: BudgetEntriesCategory::ENTRY_TYPES.stringify_keys[params[:entry_type]])
    end
  end

  def create
    send :new

    if @budget_entry.save
      @project.budget.touch if @project.budget

      flash[:notice] = t :budget_entry_successful_create
      redirect_to project_budget_path(@project)
    else
      render :action => 'new'
    end
  end

  def edit
    @budget_entry = BudgetEntry.find(params[:id])
    @budget_entry.safe_attributes = params[:budget_entry]

    @budget_entries_categories = @project.budget_entries_categories
  end

  def update
    send :edit

    if @budget_entry.save
      @project.budget.touch if @project.budget

      flash[:notice] = t :budget_entry_successful_update
      redirect_to project_budget_path(@project)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @budget_entry = BudgetEntry.find(params[:id])
    @budget_entry.destroy

    @project.budget.touch if @project.budget

    redirect_back_or_default project_budget_path(@project)
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
      redirect_to @project, flash: { error: l(:error_custom_project_dates_are_required) } unless @project.custom_start_date && @project.custom_end_date
      
      @budget = Budget.where(project_id: @project.id).first_or_create!
    end
end
