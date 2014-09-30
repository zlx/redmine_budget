class BudgetRaport
  unloadable

  attr_reader :calculator, :wages_type, :budget_entries_type, :user_raports

  delegate :budget, :works_by_user_and_role, :works_by_user, :start_date, :end_date, to: :calculator

  def initialize(budget_calculator, wages_type = "cost", budget_entries_type = "cost")
    @calculator = budget_calculator
    @wages_type = wages_type
    @budget_entries_type = budget_entries_type

    generate!
  end

  def generate!
    maximum_member_roles_count = budget.project.members.map(&:roles).map(&:count).max

    @user_raports = Hash[budget.project.members.map do |member|
      user_raport = {}

      user_raport[:user] = member.user

      user_raport[:roles] = Hash[member.roles.map do |role|
        row = works_by_user_and_role[member.user_id][role.id] if role && works_by_user_and_role[member.user_id]

        role_raport = {
          role: role,
          hours_counts_and_wages: (row[:periods]
            .group_by { |wage_period| wage_period["wage_period_id"].to_i }
            .map do |_, wage_periods|
              hours_count = wage_periods.map { |wp| wp["hours_count"] }.sum
              sum = wage_periods.map { |wp| wp[wages_type] }.sum
              wage = wage_periods.first["#{wages_type}_per_hour"]

              "#{hours_count.round(2)} h x #{wage.round(2)} #{I18n.t(:budget_currency)}"
            end.join("\n") if row),
        }

        [role.id, role_raport]
      end]

      user_raport[:total_member_hours_netto_sum] = works_by_user[member.user_id]["real_#{wages_type}".to_sym].round(2) if works_by_user[member.user_id]
      user_raport[:total_member_hours_netto_sum] ||= 0.0
      user_raport[:total_member_hours_brutto_sum] = (user_raport[:total_member_hours_netto_sum] * (1 + budget.hour_wage_tax_percent / 100)).round(2)

      # For every budget_entries_category of given type,
      # show its sum for every user.
      user_raport[:total_member_budget_entries_netto_sum] = 0.0
      user_raport[:total_member_budget_entries_brutto_sum] = 0.0

      user_raport[:budget_entries_categories] = Hash[budget_entries_categories.map do |budget_entries_category|

        budget_entries = budget_entries_category.budget_entries.real
          .select { |budget_entry| budget_entry.user_id == member.user_id }

        budget_entries.each do |budget_entry|
          user_raport[:total_member_budget_entries_netto_sum] += budget_entry.netto_amount
          user_raport[:total_member_budget_entries_brutto_sum] += budget_entry.brutto_amount
        end

        category_raport = {
          category: budget_entries_category,
          netto_sum: (budget_entries.map(&:netto_amount).sum || 0.0),
          brutto_sum: (budget_entries.map(&:brutto_amount).sum || 0.0)
        }

        [budget_entries_category.id, category_raport]
      end]

      user_raport[:total_member_netto_sum] = user_raport[:total_member_hours_netto_sum] + user_raport[:total_member_budget_entries_netto_sum]
      user_raport[:total_member_brutto_sum] = user_raport[:total_member_hours_brutto_sum] + user_raport[:total_member_budget_entries_brutto_sum]

      [member.user_id, user_raport]
    end]
  end

  def to_table
    maximum_member_roles_count = budget.project.members.map(&:roles).map(&:count).max

    rows = []
    rows << [
      I18n.t("user", scope: :budget_raport)
    ] + ([
      I18n.t("role", scope: :budget_raport),
      I18n.t("hours_count_and_#{wages_type}_wage", scope: :budget_raport)
    ] * maximum_member_roles_count) + [
      I18n.t("total_hours_netto_#{wages_type}", scope: :budget_raport),
      I18n.t("total_hours_brutto_#{wages_type}", scope: :budget_raport),
    ] + (budget_entries_categories.map do |category|
      "#{I18n.t("#{budget_entries_type.pluralize}_category")}: #{category.name}"
    end) + [
      I18n.t("total_#{budget_entries_type}_entries_netto_sum", scope: :budget_raport),
      I18n.t("total_#{budget_entries_type}_entries_brutto_sum", scope: :budget_raport),
      I18n.t("total_netto_sum", scope: :budget_raport),
      I18n.t("total_brutto_sum", scope: :budget_raport),
    ]

    rows += user_raports.values.map do |user_raport|
      [
        user_raport[:user].name
      ] + (user_raport[:roles].values.map do |role_raport|
        [
          role_raport[:role].name,
          role_raport[:hours_counts_and_wages],
        ]
      end.flatten + [nil] * 2 * (maximum_member_roles_count - user_raport[:roles].count)) + [
        user_raport[:total_member_hours_netto_sum],
        user_raport[:total_member_hours_brutto_sum],
      ] + (budget_entries_categories.map do |category|
        user_raport[:budget_entries_categories][category.id][:netto_sum]
      end.flatten) + [
        user_raport[:total_member_budget_entries_netto_sum],
        user_raport[:total_member_budget_entries_brutto_sum],
        user_raport[:total_member_netto_sum],
        user_raport[:total_member_brutto_sum],
      ]
    end

    rows[0].count.times.map do |i|
      rows.count.times.map do |j|
        rows[j][i]
      end
    end
  end

  private

  def budget_entries_categories
    calculator.entries_categories_for_type(budget_entries_type)
  end
end
