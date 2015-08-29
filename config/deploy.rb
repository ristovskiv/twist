set :application, 'twist'
set :repo_url, 'git://github.com/radar/twist'
set :deploy_to, '/var/www/twist'
set :bundle_flags, '--deployment'
set :linked_files, %w{config/initializers/mail.rb config/database.yml}
set :linked_dirs, %w{log tmp public/system}

set :chruby_ruby, 'ruby-2.2.3'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :sudo, "service unicorn-twist restart"
    end
  end

  after "deploy:published", "deploy:restart"
  after :finishing, 'deploy:cleanup'

end