require 'rubygems'
require 'bundler'
require 'rake'
require 'rake/testtask'
require 'rspec/core/rake_task'

task :default => 'spec:unit' do
end

namespace :spec do
  desc "Run acceptance specs"
  RSpec::Core::RakeTask.new('unit') do |t|
    t.pattern = 'spec/lib/**/*_spec.rb'
  end
end

begin
  require "jeweler"
  Jeweler::Tasks.new do |gem|
    gem.name    = "flexi_model"
    gem.summary = "Build flexible database model with dynamic fields (right now based on ActiveRecord soon it will work with mongoid too)"
    gem.homepage = 'https://github.com/we4tech/flexi-model/'
    gem.description = 'Flexible Model'
    gem.email   = ["hasan@somewherein.net"]
    gem.authors = ["nhm tanveer hossain khan"]
    gem.files   = Dir["{lib}/**/*", "{spec}"]
  end

  Jeweler::GemcutterTasks.new
rescue
  puts "Jeweler or dependency not available."
end