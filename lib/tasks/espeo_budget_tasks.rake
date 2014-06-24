namespace :espeo_budget do
  desc "Send warnings about usage of budget's resources, if any needed."
  task :send_warnings => :environment do
    Budget.find_each do |budget|
      budget.warn_about_threshold
    end
  end
end
