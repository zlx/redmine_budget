module EspeoBudget
  class Hooks < Redmine::Hook::ViewListener

    # Add time_entry.role_id and time_entry.user_id fields to the timelog form.
    def view_timelog_edit_form_bottom(context = {})
      time_entry = context[:time_entry]

      context[:controller].send(:render_to_string, {
        :partial => "timelog/form_role",
        :locals => context.merge({
          roles_collection: roles_collection_for_select_options(time_entry.user_id, time_entry.project_id)
        })
      })
      
      if time_entry.project ? User.current.allowed_to?(:edit_time_entries, time_entry.project) : User.current.allowed_to_globally?(:edit_time_entries, {})
        assignable_users = (
          [User.current] + 
          (
            (time_entry.project ? 
                time_entry.project.assignable_users 
              : User.status(User::STATUS_ACTIVE) 
            ) || []
          )
        ).uniq

        context[:controller].send(:render_to_string, {
          :partial => "timelog/form_user",
          :locals => context.merge({
            users_collection: principals_options_for_select(assignable_users, time_entry.user_id)
          })
        })
      end
    end

    private

      def roles_collection_for_select_options(user_id, project_id)
        member = Member.where(user_id: user_id, project_id: project_id).first
        roles = (member.roles if member) || []
        roles.map { |r| [r.name, r.id] }
      end
  end
end
