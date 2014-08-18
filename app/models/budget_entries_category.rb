class BudgetEntriesCategory < ActiveRecord::Base
  include Redmine::SafeAttributes

  unloadable

  ENTRY_TYPES = Wage::TYPES.dup

  belongs_to :project, inverse_of: :budget_entries
  has_many :budget_entries, inverse_of: :category, foreign_key: :category_id, dependent: :delete_all

  validates_presence_of :project, :name, :entry_type
  validates_inclusion_of :entry_type, :in => ENTRY_TYPES.values
  validates_numericality_of :tax, inclusion: { greater_than: 0 }

  after_initialize :set_defaults, if: -> { new_record? }
  
  # Declare #incomes, #costs scopes.
  ENTRY_TYPES.keys.each do |entry_type|
    scope entry_type.to_s.pluralize, -> { where(entry_type: ENTRY_TYPES[entry_type]) }
  end

  safe_attributes 'name', 'netto_amount', 'tax', 'entry_type'

  private

    def set_defaults
      self[:netto_amount] = 0
      self[:tax] = 0
    end
end
