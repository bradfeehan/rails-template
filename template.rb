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
# GitHub Actions
########################################

directory '.github'
git add: '.github'
git_commit 'Setup GitHub Actions workflows'

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
# Rails new
########################################

git add: '--all'
git_commit 'rails new', %w[--no-verify]

# Use .ruby-version to configure version manager and also in the Gemfile
gsub_file 'Gemfile', /^ruby\s.*$/, %q(ruby "~> #{File.read(File.expand_path('.ruby-version', __dir__)).split('-').last}")

# Extra dependencies
gem 'active_decorator'
gem 'argon2'
gem 'good_job'
gem 'gretel'
gem 'lograge'
gem 'pagy', '~> 6.0'
gem 'paper_trail'
gem 'pgcli-rails'
gem 'pundit'
gem 'rails_admin'
gem 'rodauth-rails'
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

  %w[arm64-darwin-22 ruby x86_64-linux].each do |platform|
    run "bundle lock --add-platform #{platform}"
  end

  run 'bundle install'
  git_commit 'bundle lock --add-platform {arm64-darwin-22,ruby,x86_64-linux}', %w[--no-verify]

  run 'bundle cache'
  git add: '--all'
  git_commit 'bundle cache', %w[--no-verify]

  # Generate binstubs
  run_and_commit 'bin/bundle binstubs rspec-core rubocop sorbet tapioca', %w[--no-verify]

  ########################################
  # Assets
  ########################################

  run 'yarn add autoprefixer chokidar @csstools/postcss-sass @fortawesome/fontawesome-free postcss postcss-flexbugs-fixes postcss-scss postcss-url tailwindcss @tailwindcss/forms @tailwindcss/typography'
  gsub_file 'package.json', /^(\s*"build:css":\s*"postcss).*$/, '\1 app/assets/stylesheets --base --dir app/assets/builds --ext css"'

  prepend_to_file 'postcss.config.js', "const path = require('node:path');\n"

  inject_into_file 'postcss.config.js', before: "  plugins: [\n" do
    "  syntax: 'postcss-scss',\n"
  end

  inject_into_file 'postcss.config.js', after: "  plugins: [\n" do
    <<~EOF
      require('@csstools/postcss-sass')({
        includePaths: [
          "node_modules",
          "app/assets/stylesheets",
        ],
      }),
      require('postcss-url')({
        url: 'copy',
        basePath: path.resolve('node_modules'),
        assetsPath: path.resolve('app/assets/builds'),
        useHash: false,
      }),
      require('tailwindcss'),
      require('postcss-flexbugs-fixes'),
    EOF
  end

  run 'yarn remove postcss-nesting'
  gsub_file 'postcss.config.js', /\s*require\('postcss-nesting'\),/, ''

  copy_file 'tailwind.config.js'

  remove_file 'app/assets/stylesheets/application.postcss.css'
  copy_file 'app/assets/stylesheets/application.css'

  git add: '--all'
  git_commit 'Configure PostCSS', %w[--no-verify]

  ########################################
  # Rails Admin
  ########################################

  route "mount RailsAdmin::Engine => '/admin', as: 'rails_admin'"
  inject_into_file 'config/initializers/assets.rb', <<~EOF
    Rails.application.config.assets.paths << Rails.root.join('node_modules/@fortawesome/fontawesome-free/webfonts')
  EOF
  copy_file 'config/initializers/rails_admin.rb'
  run "yarn add rails_admin@3.1.2"
  copy_file 'app/javascript/rails_admin.js'
  copy_file 'app/assets/stylesheets/rails_admin.scss'

  git add: '--all'
  git_commit 'rails generate rails_admin:install', %w[--no-verify]

  ########################################
  # Set up database
  ########################################

  rails_command 'db:reset'
  rails_command 'db:migrate'
  rails_command 'db:seed'

  git add: '--all'
  git_commit 'rails db:reset db:migrate db:seed', %w[--no-verify]

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
  # Gretel
  ########################################

  generate 'gretel:install'
  git add: '--all'
  git_commit 'Setup Gretel', %w[--no-verify]

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
  # Paper Trail
  ########################################

  generate 'paper_trail:install', '--with-changes'

  create_versions_migration = Dir.glob(File.expand_path('db/migrate/*_create_versions.rb', destination_root)).first
  gsub_file create_versions_migration, /^(\s*t\.)text(\s*:object),\s*limit:.*$/, '\1jsonb\2'

  add_object_changes_migration = Dir.glob(File.expand_path('db/migrate/*_add_object_changes_to_versions.rb', destination_root)).first
  gsub_file add_object_changes_migration, /^(\s*add_column\s*:versions,\s*:object_changes,\s*:)text,\s*limit:.*$/, '\1jsonb'

  git add: '--all'
  git_commit 'Setup Paper Trail', %w[--no-verify]

  ########################################
  # Pundit
  ########################################

  generate 'pundit:install'

  inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController' do
    "  include Pundit::Authorization\n"
  end

  inject_into_file 'app/policies/application_policy.rb', before: "class ApplicationPolicy\n" do
    "# Base policy class for Pundit\n"
  end

  inject_into_file 'app/policies/application_policy.rb', before: "  class Scope\n" do
    "  # Base abstract policy scope class for Pundit\n"
  end

  git add: '--all'
  git_commit 'Setup Pundit', %w[--no-verify]

  ########################################
  # Rodauth
  ########################################

  generate "rodauth:install --argon2"

  inject_into_file "app/misc/rodauth_app.rb", before: "class RodauthApp < Rodauth::Rails::App\n" do
    "# Rodauth app class\n"
  end

  inject_into_file "app/misc/rodauth_main.rb", before: "class RodauthMain < Rodauth::Rails::Auth\n" do
    "# Rodauth main class\n"
  end

  inject_into_file "app/models/account.rb", before: "class Account < ApplicationRecord\n" do
    "# Rodauth account which is able to log in to the site\n"
  end

  inject_into_file "app/mailers/rodauth_mailer.rb", before: "class RodauthMailer < ApplicationMailer" do
    "# Base mailer class for mail sent from Rodauth\n"
  end

  git add: '--all'
  git_commit 'rails generate rodauth:install --argon2', %w[--no-verify]

  ########################################
  # RSpec
  ########################################

  generate 'rspec:install'

  inject_into_file 'spec/rails_helper.rb', after: "# Add additional requires below this line. Rails is not loaded until this point!\n" do
    "  require 'paper_trail/frameworks/rspec'\n"
  end

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
  rails_command 'db:seed'
  git add: '--all'
  git_commit 'rails db:reset db:migrate db:seed', %w[--no-verify]

  ########################################
  # Sorbet
  ########################################

  run_and_commit 'bin/bundle exec tapioca init', %w[--no-verify]
end
