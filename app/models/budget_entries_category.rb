class BudgetEntriesCategory < ActiveRecord::Base
  include Redmine::SafeAttributes

  unloadable

  ENTRY_TYPES = {
    :income => 1,
    :cost => 2
  }

  belongs_to :project, inverse_of: :budget_entries
  has_many :budget_entries, inverse_of: :category, foreign_key: :category_id, dependent: :delete_all

  validates_presence_of :project, :name, :entry_type
  validates_inclusion_of :entry_type, :in => ENTRY_TYPES.values

  # Declare #incomes, #costs scopes.
  ENTRY_TYPES.keys.each do |entry_type|
    scope entry_type.to_s.pluralize, -> { where(entry_type: ENTRY_TYPES[entry_type]) }
  end

  safe_attributes 'name', 'entry_type'

  def planned_amount
    budget_entries.planned.map(&:netto_amount).sum
  end

  def real_amount
    budget_entries.real.map(&:netto_amount).sum
  end
end
