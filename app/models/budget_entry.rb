class BudgetEntry < ActiveRecord::Base
  unloadable

  ENTRY_TYPES = Wage::TYPES.dup

  belongs_to :project, inverse_of: :budget_entries
  belongs_to :category, class_name: "BudgetEntriesCategory", foreign_key: :category_id, inverse_of: :budget_entries
  belongs_to :issue
  belongs_to :user

  validates_presence_of :project, :category, :entry_type
  validates_inclusion_of :entry_type, :in => ENTRY_TYPES.values
  validates_numericality_of :netto_amount, :tax, :deposit_amount, inclusion: { greater_than: 0 }

  # Declare #incomes, #costs scopes.
  ENTRY_TYPES.keys.each do |entry_type|
    scope entry_type.to_s.pluralize, -> { where(entry_type: ENTRY_TYPES[entry_type]) }
  end
end
