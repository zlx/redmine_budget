class BudgetEntriesCategory < ActiveRecord::Base
  unloadable

  include Redmine::SafeAttributes

  belongs_to :project, inverse_of: :budget_entries
  has_many :budget_entries, inverse_of: :category, foreign_key: :category_id, dependent: :delete_all

  validates_presence_of :project, :name, :entry_type
  validates_inclusion_of :entry_type, :in => BudgetEntry::ENTRY_TYPES.values
  validates_numericality_of :netto_amount, :tax, inclusion: { greater_than: 0 }

  after_initialize :set_defaults, if: -> { new_record? }
  
  # Declare #incomes, #costs scopes.
  BudgetEntry::ENTRY_TYPES.keys.each do |entry_type|
    scope entry_type.to_s.pluralize, -> { where(entry_type: BudgetEntry::ENTRY_TYPES[entry_type]) }
  end

  safe_attributes 'name', 'netto_amount', 'tax', 'entry_type'

  private

    def set_defaults
      self[:netto_amount] = 0
      self[:tax] = 0
    end
end
