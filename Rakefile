#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

# Packaging tasks
Bundler::GemHelper.install_tasks

# Gem signing
task 'before_build' do
  signing_key = File.expand_path("~/.gem/librato-private_key.pem")
  if signing_key
    puts "Key found: signing gem..."
    ENV['GEM_SIGNING_KEY'] = signing_key
  else
    puts "WARN: signing key not found, gem not signed"
  end
end
task :build => :before_build

# Console
desc "Open an console session preloaded with this library"
task :console do
  sh "pry -r ./lib/librato-rack.rb"
end

# Testing
require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
  t.warning = false
end

task :default => :test
