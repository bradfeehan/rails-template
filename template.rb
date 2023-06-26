def source_paths
  [File.expand_path('root', __dir__)]
end

def git_commit(message, args = [])
  args << '--message' << "'#{message}'"
  git commit: args.join(' ')
end

def run_and_commit(command)
  run command
  git add: '--all'
  git_commit command
end

########################################
# Initial commit
########################################

git :init
git_commit <<~MSG, %w[--allow-empty]
  Initial commit

  Empty initial commit to allow rebasing later.
  See: https://coderwall.com/p/m_pgbg
MSG

########################################
# Editor Config
########################################

copy_file '.editorconfig'
git add: '.editorconfig'
git_commit <<~MSG
  Add Editorconfig

  EditorConfig automatically configures many popular editors to use a
  consistent coding style for a project. Read more about it here:

  http://editorconfig.org

  These settings are common in the open-source world:

    - UTF-8 encoding
    - Unix line endings
    - Trailing newline on last line
    - Trim trailing whitespace

  My personal preferences:

    - 2 spaces indentation in most files (common in Ruby projects)
    - 4 spaces indentation in plain-text files (necessary for Markdown)
MSG

########################################
# Rails new
########################################

git add: '--all'
git_commit 'rails new'

# Use .ruby-version to configure version manager and also in the Gemfile
gsub_file 'Gemfile', /^ruby\s.*$/, %q(ruby "~> #{File.read(File.expand_path('.ruby-version', __dir__)).split('-').last}")

# Extra dependencies
gem 'active_decorator'
gem 'good_job'
gem 'lograge'
gem 'pagy', '~> 6.0'
gem 'pgcli-rails'
gem 'sorbet-runtime'

gem_group :development do
  gem 'tapioca', require: false
end

gem_group :development, :test do
  gem 'factory_bot_rails', require: false
  gem 'faker', require: false
  gem 'pry', '~> 0.14.2', require: false
  gem 'pry-rails', require: false
  gem 'shoulda-matchers', require: false
  gem 'rspec-its', require: false
  gem 'rspec-rails', '~> 6.0', require: false
  gem 'rubocop', '~> 1.53', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-sorbet', require: false
  gem 'sorbet'
end

git add: '--all'
git_commit 'Add dependencies to Gemfile'

after_bundle do
  git add: '--all'
  git_commit 'bundle install'

  # Generate binstubs
  run_and_commit 'bin/bundle binstubs rspec-core rubocop sorbet tapioca'

  ########################################
  # good_job
  ########################################

  application 'config.active_job.queue_adapter = :good_job'
  generate 'good_job:install'
  git add: '--all'
  git_commit 'rails generate good_job:install'

  append_to_file 'config/puma.rb', <<~END
    before_fork { GoodJob.shutdown }
    on_worker_boot { GoodJob.restart }
    on_worker_shutdown { GoodJob.shutdown }

    PUMA_MAIN_PID = Process.pid
    at_exit { GoodJob.shutdown if Process.pid == PUMA_MAIN_PID }
  END

  ########################################
  # Pagy
  ########################################

  # Pagy setup
  copy_file 'config/initializers/pagy.rb'
  inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController' do
    "  include Pagy::Backend\n"
  end
  inject_into_module 'app/helpers/application_helper.rb', 'ApplicationHelper' do
    "  include Pagy::Frontend\n"
  end
  application "Rails.application.config.assets.paths << Pagy.root.join('javascripts')"
  git add: '--all'
  git_commit 'Setup Pagy'

  # TESTING ONLY
  generate 'scaffold', 'foo name:string'
  git add: '--all'
  git_commit 'rails generate scaffold foo name:string'

  ########################################
  # RSpec
  ########################################

  generate 'rspec:install'
  git add: '--all'
  git_commit 'rails generate rspec:install'

  ########################################
  # Rubocop
  ########################################

  copy_file '.rubocop.yml'
  run_and_commit 'bin/bundle exec rubocop --autocorrect-all'

  rails_command 'db:prepare'
  git add: '--all'
  git_commit 'rails db:prepare'

  ########################################
  # Sorbet
  ########################################

  run_and_commit 'bin/bundle exec tapioca init'
  run_and_commit 'bin/bundle exec tapioca gems'
end
