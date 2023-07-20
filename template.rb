def source_paths
  [File.expand_path('root', __dir__)]
end

def git_commit(message, args = [])
  args << '--message' << "'#{message}'"
  args << '--allow-empty'
  git commit: args.join(' ')
end

def run_and_commit(command, args = [])
  run command
  git add: '--all'
  git_commit command, args
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
# Docker
########################################

copy_file '.dockerignore'
copy_file 'Dockerfile'
template 'docker-compose.yml.tt'
copy_file 'docker-compose.override.example.yml'
run 'ln -s docker-compose.override.example.yml docker-compose.override.yml'
directory 'vendor/keys'
git add: '.dockerignore Dockerfile docker-compose*.yml vendor/keys'
git_commit 'Setup Docker'

########################################
# Pre-commit hook
########################################

%w[filename-check pre-commit].each do |binstub|
  copy_file "bin/#{binstub}", mode: :preserve
  git add: "bin/#{binstub}"
end

%w[.stylelintignore .stylelintrc.json .v8rrc.yml .yamllint.yml].each do |rcfile|
  copy_file rcfile
  git add: rcfile
end

run 'ln -s ../../bin/pre-commit .git/hooks'
git_commit 'Setup pre-commit hook and linters'

########################################
# VS Code Dev Container
########################################

directory '.devcontainer'
git add: '.devcontainer'
git_commit 'Setup VS Code Dev Container'

########################################
# GitHub Actions
########################################

directory '.github'
git add: '.github'
git_commit 'Setup GitHub Actions workflows'

########################################
# Rails new
########################################

git add: '--all'
git_commit 'rails new', %w[--no-verify]

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

copy_file '.bundle/config'
git add: '-f .bundle/config'
git_commit 'Configure Bundler to cache gems locally'

after_bundle do
  git add: '--all'
  git_commit 'bundle install', %w[--no-verify]

  run 'bundle cache'
  git add: '--all'
  git_commit 'bundle cache', %w[--no-verify]

  # Generate binstubs
  run_and_commit 'bin/bundle binstubs rspec-core rubocop sorbet tapioca', %w[--no-verify]

  ########################################
  # good_job
  ########################################

  application 'config.active_job.queue_adapter = :good_job'
  generate 'good_job:install'
  good_job_migration = Dir.glob(File.expand_path('db/migrate/*_create_good_jobs.rb', destination_root)).first

  gsub_file good_job_migration, /^(\s*t\.boolean.*)$/, '\1, null: false, default: false'

  git add: '--all'
  git_commit 'rails generate good_job:install', %w[--no-verify]

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
  git_commit 'Setup Pagy', %w[--no-verify]

  ########################################
  # RSpec
  ########################################

  generate 'rspec:install'
  git add: '--all'
  git_commit 'rails generate rspec:install', %w[--no-verify]

  ########################################
  # Rubocop
  ########################################

  copy_file '.rubocop.yml'
  run_and_commit 'bin/bundle exec rubocop --autocorrect-all'

  # TESTING ONLY
  gsub_file 'Procfile.dev', /^web:.*$/, '\0 --binding 0.0.0.0'
  generate 'scaffold', 'foo name:string'
  git add: '--all'
  git_commit 'rails generate scaffold foo name:string', %w[--no-verify]

  rails_command 'db:reset'
  rails_command 'db:migrate'
  git add: '--all'
  git_commit 'rails db:reset db:migrate', %w[--no-verify]

  ########################################
  # Sorbet
  ########################################

  # TODO: uncomment
  # run_and_commit 'bin/bundle exec tapioca init', %w[--no-verify]
end
