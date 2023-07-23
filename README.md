rails-template
==============

A [Rails Application Template] with my preferred setup:

[Rails Application Template]: <https://guides.rubyonrails.org/rails_application_templates.html>

- An [empty initial commit]
- My preferred [EditorConfig]:
    - UTF-8 encoding
    - Unix line endings
    - Trailing newline on last line
    - Trim trailing whitespace
    - 2 spaces indentation in most files (common in Ruby projects)
    - 4 spaces indentation in plain-text files (necessary for Markdown)
- Docker environment
    - Dockerfile based on official Ruby image, with Node and Yarn
    - Docker Compose development environment with official Postgres image
- Pre-commit hook to run linters, with no dependencies other than the shell
    - Run against the state in the index, excluding uncommited changes
    - Check filenames for invalid patterns
        - Enforce `.yml` over `*.yaml`
        - Prevent capital letters in filenames
    - Check files for whitespace errors and merge conflict markers
    - [`actionlint`]: GitHub Actions workflow linter
    - [`hadolint`]: Dockerfile linter
    - [`v8r`]: JSON schema validation
    - [`rubocop`]: Ruby style guide linter
    - [`shellcheck`]: Shell script linter
    - [`stylelint`]: CSS and SCSS linter
    - [`yamllint`]: YAML file linter
- GitHub Actions for linting and testing on push
- Ruby version management with Bundler and `.ruby-version`
    - [Consistency with version requirement in Gemfile]
    - Configure Bundler to cache gems locally, to allow offline install
        - For M1/Silicon macOS and x86_64 Linux architectures (as I use)
- Rails add-ons
    - [ActiveDecorator]: Presenter pattern implementation
    - [GoodJob]: Postgres-based backend for ActiveJob
    - [Gretel]: Helper to show navigation breadcrumbs
    - [Lograge]: Improved defaults to improve Rails logging
    - [Pagy]: Pagination for collections of items in Ruby
    - [PaperTrail]: Track changes to models for auditing or versioning
    - [`pgcli-rails`]: Replaces Rails PostgreSQL `dbconsole` with `pgcli`
    - [Pundit]: Authorization framework to manage permissions
    - [Rails Admin]: Admin dashboard and data management, in a Rails engine
    - [Rodauth]: Authentication framework to manage user accounts
        - [`rodauth-rails`]: Rails integration for Rodauth
        - [`ruby-argon2`]: Better key derivation function than `bcrypt`
    - [Sorbet]: Static type checking for Ruby
        - [Tapioca]: Generate RBI files for gems and DSLs
    - [Propshaft]: Simplified asset pipeline for Rails 7
        - [PostCSS]: CSS preprocessor framework
        - [Tailwind CSS]: Utility-based CSS framework
        - [Autoprefixer]: Adds vendor prefixes to CSS based on [Can I Use...]
        - [Font Awesome]: Icon library
- Testing
    - [Factory Bot]: Fixture objects for test data
        - [`factory_bot_rails`]: Factory Bot integration for Rails models
    - [Faker]: Generates plausible/realistic data for addresses, names, etc.
    - [Pry]: Developer console for Ruby, better replacement for `irb`
        - [`pry-rails`]: Use Pry for `rails console`
    - [RSpec]: Readable testing framework for Ruby
        - [`rspec-its`]: Helper method `its` to test properties of `subject`
        - [`rspec-rails`]: Replace Minitest in Rails with RSpec
        - [Shoulda Matchers]: Simple one-liner tests for Rails

[empty initial commit]: <https://www.garfieldtech.com/blog/git-empty-commit>
[EditorConfig]: <http://editorconfig.org>

[`actionlint`]: <https://github.com/rhysd/actionlint>
[`hadolint`]: <https://github.com/hadolint/hadolint>
[`v8r`]: <https://www.npmjs.com/package/v8r>
[`rubocop`]: <https://rubocop.org>
[`shellcheck`]: <https://www.shellcheck.net>
[`stylelint`]: <https://stylelint.io>
[`yamllint`]: <https://yamllint.readthedocs.io>

[Consistency with version requirement in Gemfile]: <https://andycroll.com/ruby/read-ruby-version-in-your-gemfile/>

[ActiveDecorator]: <https://github.com/amatsuda/active_decorator>
[GoodJob]: <https://island94.org/2020/07/introducing-goodjob-1-0>
[Gretel]: <https://github.com/kzkn/gretel>
[Lograge]: <https://github.com/roidrage/lograge>
[Pagy]: <https://github.com/ddnexus/pagy>
[PaperTrail]: <https://github.com/paper-trail-gem/paper_trail>
[`pgcli-rails`]: <https://github.com/mattbrictson/pgcli-rails>
[Pundit]: <https://github.com/varvet/pundit>
[Rails Admin]: <https://github.com/railsadminteam/rails_admin>
[Rodauth]: <https://github.com/jeremyevans/rodauth>
[`rodauth-rails`]: <https://github.com/janko/rodauth-rails>
[`ruby-argon2`]: <https://github.com/technion/ruby-argon2>
[Sorbet]: <https://sorbet.org>
[Tapioca]: <https://github.com/Shopify/tapioca>
[Propshaft]: <https://github.com/rails/propshaft>
[PostCSS]: <https://postcss.org>
[Tailwind CSS]: <https://tailwindcss.com>
[Autoprefixer]: <https://github.com/postcss/autoprefixer>
[Can I Use...]: <https://caniuse.com>
[Font Awesome]: <https://fontawesome.com>

[Factory Bot]: <https://github.com/thoughtbot/factory_bot>
[`factory_bot_rails`]: <https://github.com/thoughtbot/factory_bot_rails>
[Faker]: <https://github.com/faker-ruby/faker>
[Pry]: <https://github.com/pry/pry>
[`pry-rails`]: <https://github.com/pry/pry-rails>
[RSpec]: <https://rspec.info>
[`rspec-its`]: <https://github.com/rspec/rspec-its>
[`rspec-rails`]: <https://github.com/rspec/rspec-rails>
[Shoulda Matchers]: <https://matchers.shoulda.io>
