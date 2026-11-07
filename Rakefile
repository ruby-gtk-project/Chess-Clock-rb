# frozen_string_literal: true

# kettle-jem:freeze
# To retain chunks of comments & code during kettle-jem templating:
# Wrap custom sections with freeze markers (e.g., as above and below this comment chunk).
# kettle-jem will then preserve content between those markers across template runs.
# kettle-jem:unfreeze

# chess-clock-rb Rakefile v7.1.28 - 2026-10-11
# Ruby 2.3 (Safe Navigation) or higher required
#
# See LICENSE.md for license information.
#
# Copyright (c) 2026 ruby-gtk-project (github.com)
#
# Expected to work in any project that uses Bundler.
#
# Sets up tasks for appraisal2, floss_funding, kettle-jem, kettle-dev, rspec, minitest, rubocop_gradual, reek, yard, and stone_checksums.
#
# rake appraisal:install                      # Install Appraisal gemfiles (initial setup...
# rake appraisal:reset                        # Delete Appraisal lockfiles (gemfiles/*.gemfile.lock)
# rake appraisal:generate                     # Generate Appraisal gemfiles without resolving...
# rake appraisal:update                       # Generate and update Appraisal gemfiles
# rake bench                                  # Run all benchmarks (alias for bench:run)
# rake bench:list                             # List available benchmark scripts
# rake bench:run                              # Run all benchmark scripts (skips on CI)
# rake build:generate_checksums               # Generate both SHA256 & SHA512 checksums i...
# rake bundle:audit:check                     # Checks the Gemfile.lock for insecure depe...
# rake bundle:audit:update                    # Updates the bundler-audit vulnerability d...
# rake ci:act[opt]                            # Run 'act' with a selected workflow
# rake coverage                               # Run specs w/ coverage and open results in...
# rake default                                # Default tasks aggregator
# rake install                                # Build and install chess-clock-rb-1.0.0.gem in...
# rake install:local                          # Build and install chess-clock-rb-1.0.0.gem in...
# rake kettle:jem:install                     # Internal target used by `kettle-jem install`
# rake kettle:jem:selftest                    # Self-test: template chess-clock-rb against itse...
# rake kettle:jem:template                    # Internal target used by scoped `kettle-jem template --only`
# rake reek                                   # Check for code smells
# rake reek:update                            # Run reek and store the output into the RE...
# rake release[remote]                        # Create tag v1.0.0 and build and push kett...
# rake rubocop_gradual                        # Run RuboCop Gradual
# rake rubocop_gradual:autocorrect            # Run RuboCop Gradual with autocorrect (onl...
# rake rubocop_gradual:autocorrect_all        # Run RuboCop Gradual with autocorrect (saf...
# rake rubocop_gradual:check                  # Run RuboCop Gradual to check the lock file
# rake rubocop_gradual:force_update           # Run RuboCop Gradual to force update the l...
# rake rubocop_gradual_debug                  # Run RuboCop Gradual
# rake rubocop_gradual_debug:autocorrect      # Run RuboCop Gradual with autocorrect (onl...
# rake rubocop_gradual_debug:autocorrect_all  # Run RuboCop Gradual with autocorrect (saf...
# rake rubocop_gradual_debug:check            # Run RuboCop Gradual to check the lock file
# rake rubocop_gradual_debug:force_update     # Run RuboCop Gradual to force update the l...
# rake spec                                   # Run RSpec code examples
# rake test                                   # Run tests
# rake yard                                   # Generate YARD Documentation
# rake yard:lint                              # Lint YARD Documentation
#

# simplecov:disable
if !Dir[File.join(__dir__, "*.gemspec")].empty?
  require "bundler/gem_tasks"
end
# simplecov:enable

# Define a base default task early so other files can enhance it.
desc "Default tasks aggregator"
task :default do
  puts "Default task complete."
end

# Without this, a generated docs/ directory makes Rake resolve the bare
# name `docs` as an up-to-date file task, so `rake docs` exits 0 having
# regenerated nothing.
desc "Generate YARD documentation"
task docs: "yard"

# simplecov:disable
### MONOREPO FAMILY TASKS
if Dir.exist?(File.join(__dir__, "gems"))
  def family_gem_dirs
    Dir.glob(
      File.join(
        __dir__,
        "gems",
        "*",
        "*.gemspec",
      ),
    )
      .map { |path| File.dirname(path) }
      .uniq
      .sort_by { |path| File.basename(path) }
  end

  def run_kettle_family(*args)
    sh(
      "bundle",
      "exec",
      "kettle-family",
      *args,
    )
  end

  namespace :family do
    desc "List released Ruby subgems"
    task :list do
      family_gem_dirs.each { |path| puts File.basename(path) }
    end

    desc "Run release readiness checks for the Ruby gem family"
    task :readiness do
      run_kettle_family("check")
    end

    desc "Run tests for the Ruby gem family"
    task :test do
      run_kettle_family("test", "--execute")
    end

    desc "Run lint for the Ruby gem family"
    task :lint do
      run_kettle_family("lint", "--execute")
    end

    desc "Generate YARD docs for the Ruby gem family"
    task :docs do
      run_kettle_family("docs", "--execute")
    end

    desc "Report release state for the Ruby gem family"
    task :release_state do
      run_kettle_family("release-state")
    end

    desc "Run the Ruby gem family release planner"
    task :release do
      run_kettle_family("release")
    end

    desc "Execute the Ruby gem family release"
    task :release_execute do
      run_kettle_family("release", "--execute")
    end
  end
end
# simplecov:enable

# External gems that define tasks - add here!
begin
  require "kettle/dev"
  unless Kettle::Dev::RUNNING_AS == "rake"
    Kettle::Dev.install_tasks
  end
rescue LoadError
  warn("NOTE: kettle-dev isn't installed, or is disabled for #{RUBY_VERSION} in the current environment")
end

### TEMPLATING TASKS
# These tasks are installed for the `kettle-jem` executable. Run full templating
# through `kettle-jem install`; use `kettle-jem template --only PATH` only for
# scoped file updates. The executable prepares the environment and then
# delegates here when rake orchestration is needed.
kettle_jem_selftest_unavailable_note = nil
begin
  require "kettle/jem"
  if Kettle::Jem.respond_to?(:install_tasks)
    Kettle::Jem.install_tasks
  else
    kettle_jem_selftest_unavailable_note = "NOTE: kettle-jem #{Kettle::Jem::Version::VERSION} does not provide rake tasks in this environment"
  end
rescue LoadError
  kettle_jem_selftest_unavailable_note = "NOTE: kettle-jem isn't installed, or is disabled for #{RUBY_VERSION} in the current environment"
end

if kettle_jem_selftest_unavailable_note
  desc("(stub) kettle:jem:selftest is unavailable")
  task("kettle:jem:selftest") do
    warn(kettle_jem_selftest_unavailable_note)
  end
end

### RELEASE TASKS
# Setup stone_checksums
begin
  require "stone_checksums"
rescue LoadError
  desc("(stub) build:generate_checksums is unavailable")
  task("build:generate_checksums") do
    warn("NOTE: stone_checksums isn't installed, or is disabled for #{RUBY_VERSION} in the current environment")
  end
end

# kettle-jem:freeze
### DESKTOP INTEGRATION TASKS
# The port's equivalent of upstream's data/meson.build and po/meson.build.
# Upstream's build system compiles the GSettings schema, validates the desktop
# entry and the metainfo, compiles one .mo per language and installs the four
# icons; meson is not available here, so the same work is done by these tasks.
#
#   rake locale          # po/*.po  -> locale/<lang>/LC_MESSAGES/chess-clock.mo
#   rake gschema         # data/*.gschema.xml -> data/schemas/gschemas.compiled
#   rake install:data    # desktop entry, D-Bus service, metainfo, icons, schema
#   rake data            # locale + gschema
require "fileutils"

CHESS_CLOCK_APP_ID = "eu.fortysixandtwo.chessclock"
CHESS_CLOCK_TEXTDOMAIN = "chess-clock"

# Where `rake install:data` writes. DESTDIR and PREFIX follow the GNU
# conventions upstream's meson install obeys.
def chess_clock_destdir = ENV.fetch("DESTDIR", "")
def chess_clock_prefix = ENV.fetch("PREFIX", File.join(Dir.home, ".local"))
def chess_clock_datadir = File.join(chess_clock_destdir, chess_clock_prefix, "share")

def chess_clock_languages = File.read("po/LINGUAS").split("\n").map(&:strip).reject { |line| line.empty? || line.start_with?("#") }

desc("Compile po/*.po into locale/<lang>/LC_MESSAGES/#{CHESS_CLOCK_TEXTDOMAIN}.mo")
task("locale") do
  require "gettext/tools/msgfmt"
  chess_clock_languages.each do |language|
    File.join("locale", language, "LC_MESSAGES").tap do |dir|
      FileUtils.mkdir_p(dir)
      GetText::Tools::MsgFmt.run(
        File.join("po", "#{language}.po"),
        "--output",
        File.join(dir, "#{CHESS_CLOCK_TEXTDOMAIN}.mo"),
      )
    end
  end
end

def chess_clock_potfiles = File.read("po/POTFILES.in").split("\n").map(&:strip).reject { |line| line.empty? || line.start_with?("#") }

desc("Extract translatable strings from po/POTFILES.in into po/#{CHESS_CLOCK_TEXTDOMAIN}.pot")
task("pot") do
  require "gettext/tools/xgettext"
  GetText::Tools::XGetText.run(
    *chess_clock_potfiles,
    "--output",
    File.join("po", "#{CHESS_CLOCK_TEXTDOMAIN}.pot"),
    "--package-name",
    "Chess Clock",
  )
end

desc("Compile data/#{CHESS_CLOCK_APP_ID}.gschema.xml into data/schemas")
task("gschema") do
  FileUtils.mkdir_p("data/schemas")
  FileUtils.cp("data/#{CHESS_CLOCK_APP_ID}.gschema.xml", "data/schemas/")
  sh("glib-compile-schemas", "data/schemas")
end

desc("Compile the catalogues and the GSettings schema")
task("data" => ["locale", "gschema"])

namespace("install") do
  desc("Install the desktop entry, D-Bus service, metainfo, icons, schema and catalogues under PREFIX")
  task("data" => ["locale", "gschema"]) do
    # The two .in files carry no substitutions of their own except @bindir@ in
    # the service file, which is what meson fills in.
    bindir = File.join(chess_clock_prefix, "bin")

    {
      "applications/#{CHESS_CLOCK_APP_ID}.desktop"    => File.read("data/#{CHESS_CLOCK_APP_ID}.desktop.in"),
      "dbus-1/services/#{CHESS_CLOCK_APP_ID}.service" => File.read("data/#{CHESS_CLOCK_APP_ID}.service.in").gsub("@bindir@", bindir),
      "metainfo/#{CHESS_CLOCK_APP_ID}.metainfo.xml"   => File.read("data/#{CHESS_CLOCK_APP_ID}.metainfo.xml.in"),
    }.each do |relative, contents|
      File.join(chess_clock_datadir, relative).tap do |target|
        FileUtils.mkdir_p(File.dirname(target))
        File.write(target, contents)
      end
    end

    {
      "icons/hicolor/scalable/apps/#{CHESS_CLOCK_APP_ID}.svg"          => "data/icons/hicolor/scalable/apps/#{CHESS_CLOCK_APP_ID}.svg",
      "icons/hicolor/scalable/apps/#{CHESS_CLOCK_APP_ID}.Devel.svg"    => "data/icons/hicolor/scalable/apps/#{CHESS_CLOCK_APP_ID}.Devel.svg",
      "icons/hicolor/symbolic/apps/#{CHESS_CLOCK_APP_ID}-symbolic.svg" => "data/icons/hicolor/symbolic/apps/#{CHESS_CLOCK_APP_ID}-symbolic.svg",
      "glib-2.0/schemas/#{CHESS_CLOCK_APP_ID}.gschema.xml"             => "data/#{CHESS_CLOCK_APP_ID}.gschema.xml",
    }.each do |relative, source|
      File.join(chess_clock_datadir, relative).tap do |target|
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(source, target)
      end
    end

    chess_clock_languages.each do |language|
      File.join(
        chess_clock_datadir,
        "locale",
        language,
        "LC_MESSAGES",
      ).tap do |dir|
        FileUtils.mkdir_p(dir)
        FileUtils.cp(
          File.join(
            "locale",
            language,
            "LC_MESSAGES",
            "#{CHESS_CLOCK_TEXTDOMAIN}.mo",
          ),
          dir,
        )
      end
    end

    sh("glib-compile-schemas", File.join(chess_clock_datadir, "glib-2.0", "schemas"))
    sh("gtk4-update-icon-cache", "-qtf", File.join(chess_clock_datadir, "icons", "hicolor"))
  end
end
# kettle-jem:unfreeze
