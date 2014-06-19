class Budget
  unloadable

  attr_reader :project

  def initialize(project)
    @project = project
  end

  def project_role_budgets
    project.project_role_budgets.includes(:role).merge(Role.sorted)
  end

  delegate :wages, to: :project

  # Define #client_wages, #cost_wages methods.
  Wage::TYPES.each do |type, value|
    delegate type.to_s.pluralize, to: :wages
  end
end
