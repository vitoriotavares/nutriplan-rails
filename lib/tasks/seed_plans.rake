namespace :db do
  namespace :seed do
    desc "Seed plans data"
    task plans: :environment do
      load(Rails.root.join('db', 'seeds', 'plans.rb'))
    end
  end
end
