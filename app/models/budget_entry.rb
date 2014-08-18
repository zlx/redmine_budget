class BudgetEntry < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  unloadable

  belongs_to :project, inverse_of: :budget_entries
  belongs_to :category, class_name: "BudgetEntriesCategory", foreign_key: :category_id, inverse_of: :budget_entries
  belongs_to :issue
  belongs_to :user

  validates_presence_of :project, :category, :name
  validates_numericality_of :tax, :deposit_amount, inclusion: { greater_than: 0 }

  after_initialize :set_defaults, if: -> { new_record? }

  scope :planned, -> { where(planned: true) }
  scope :worked, -> { where(planned: false) }

  safe_attributes 'name', 'netto_amount', 'tax', 'deposit_amount', 'user_id', 'created_on', 'category_id', 'issue_id'

  def brutto_amount
    netto_amount * (1 + tax * 100)
  end

  private

    def set_defaults
      self[:netto_amount] = 0
      self[:tax] = 0
      self[:deposit_amount] = 0
      self[:created_on] = Date.today
    end
end
