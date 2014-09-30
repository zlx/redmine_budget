namespace :espeo_budget do
  desc "Send warnings about usage of budget's resources, if any needed."
  task :send_warnings => :environment do
    Budget.find_each do |budget|
      if mail_message = budget.warn_about_threshold
        puts "[Project \##{budget.project.id}: #{budget.project.identifier}] email with warning about used budget costs sent to: #{mail_message.bcc}"
      end
    end
  end
end
