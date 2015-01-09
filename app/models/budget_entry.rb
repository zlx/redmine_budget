class BudgetEntry < ActiveRecord::Base
  include Redmine::SafeAttributes

  unloadable

  belongs_to :project, inverse_of: :budget_entries
  belongs_to :category, class_name: "BudgetEntriesCategory", foreign_key: :category_id, inverse_of: :budget_entries
  belongs_to :issue
  belongs_to :user

  acts_as_customizable

  validates_presence_of :project, :category, :name
  validates_numericality_of :tax, :deposit_amount, greater_than: 0
  validate :assert_date_fits_project_date

  after_initialize :set_defaults, if: -> { new_record? }

  scope :planned, -> { where(planned: true) }
  scope :real, -> { where(planned: false) }

  safe_attributes 'name',
    'netto_amount',
    'tax',
    'deposit_amount',
    'user_id',
    'created_on',
    'category_id',
    'issue_id',
    'planned',
    'custom_field_values',
    'custom_fields'

  delegate :entry_type, to: :category
  delegate :entry_type_symbol, to: :category

  def brutto_amount
    (netto_amount * (1 + tax.to_f / 100)).round(2)
  end

  def cost?
    category.entry_type == BudgetEntriesCategory::ENTRY_TYPES[:cost]
  end

  def income?
    category.entry_type == BudgetEntriesCategory::ENTRY_TYPES[:income]
  end

  private

    def set_defaults
      self[:netto_amount] = 0
      self[:tax] = 0
      self[:deposit_amount] = 0
      self[:created_on] = Date.today
      self[:planned] = false
    end

    def assert_date_fits_project_date
      if self.created_on && project.custom_start_date && project.custom_end_date && !self.created_on.between?(project.custom_start_date, project.custom_end_date)
        errors.add(:created_on, "must be between project's start and end date.")
      end
    end
end
