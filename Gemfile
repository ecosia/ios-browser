source 'https://rubygems.org'

gem 'danger', :git => 'git@github.com:danger/danger.git', :branch => 'master'
gem 'danger-swiftlint'
# Ecosia: add fastlane and plugins
gem 'fastlane', '>= 2.228.0'
gem 'base64'
gem 'abbrev'
plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)