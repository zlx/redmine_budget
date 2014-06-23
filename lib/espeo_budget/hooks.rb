module EspeoBudget
  class Hooks < Redmine::Hook::ViewListener

    # Add time_entry.role field to the timelog form.
    def view_timelog_edit_form_bottom(context = {})
      time_entry = context[:time_entry]
      context[:roles_collection] = roles_collection_for_select_options(time_entry.user_id, time_entry.project_id)

      context[:controller].send(:render_to_string, {
        :partial => "timelog/form_role",
        :locals => context
      })
    end

    private

      def roles_collection_for_select_options(user_id, project_id)
        member = Member.where(user_id: user_id, project_id: project_id).first
        roles = (member.roles if member) || []
        roles.map { |r| [r.name, r.id] }
      end
  end
end
