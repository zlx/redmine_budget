class BudgetController < ApplicationController
  unloadable

  before_filter :find_project
  before_filter :authorize

  def show
  end

  def edit
  end

  def update
  end

  private

    def find_project
      @project = Project.find(params[:id])
    end
end
