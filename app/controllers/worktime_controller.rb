class WorktimeController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize

  def show
    @project_holiday = ProjectHoliday.new(project: @project)
  end

  def update
    @budget.safe_attributes = params[:budget]
    if @budget.save
      flash[:notice] = l(:worktime_successful_update, scope: :worktime)
    else
      flash[:error] = l(:database_save_error, scope: :worktime)
    end

    redirect_to project_worktime_path(@project)
  end

  def create_holiday
    @project_holiday = ProjectHoliday.new(project: @project)
    @project_holiday.safe_attributes = params[:project_holiday]
    if @project_holiday.save
      flash[:notice] = l(:project_holiday_successful_create, scope: :worktime)
    else
      flash[:error] = @project_holiday.errors.first.message if @project_holiday.errors.present?
      flash[:error] ||= l(:database_save_error, scope: :worktime)
    end

    redirect_to project_worktime_path(@project)
  end

  def destroy_holiday
    @project_holiday = ProjectHoliday.find(params[:id])
    @project_holiday.destroy if @project_holiday
    
    redirect_back_or_default project_worktime_path(@project)
  end

  private

    def find_project
      @project = Project.find(params[:project_id])
      redirect_to @project, flash: { error: l(:error_custom_project_dates_are_required) } unless @project.custom_start_date && @project.custom_end_date
      
      @budget = Budget.where(project_id: @project.id).first_or_create!
    end
end
