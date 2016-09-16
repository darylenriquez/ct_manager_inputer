ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup'

Bundler.require(:default)

require 'yaml'

# Load variables
YAML.load_file(File.expand_path('../variables.yml', __FILE__)).each {|k,v| ENV[k] = v }

# Require files from lib
Dir["./lib/*.rb"].each {|file| require file }