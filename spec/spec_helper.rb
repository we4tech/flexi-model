ENV["ENVIRONMENT"] ||= 'test'

require "rubygems"
require "bundler"
Bundler.require

require 'active_record'
require 'rspec/autorun'

require 'spec_helper/rspec'
require 'spec_helper/active_record'
require 'spec_helper/models'

require 'flexi_model'

Dir.glob(File.join('spec', 'factories', '*')).each { |f| require f }
