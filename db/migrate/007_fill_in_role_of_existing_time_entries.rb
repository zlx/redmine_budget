class FillInRoleOfExistingTimeEntries < ActiveRecord::Migration
  def up
    TimeEntry.where(role_id: nil).find_each do |time_entry|
      member = Member.where(time_entry.attributes.slice("user_id", "project_id")).first
      if member && member.roles.present?
        time_entry.role_id = member.roles.first.id
        time_entry.save! validate: false
      end
    end
  end

  def down
  end
end
