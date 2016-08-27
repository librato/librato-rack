source "https://rubygems.org"
gemspec

# test application
gem 'rack-test'
gem 'sinatra'

# mocks
gem 'mocha', :require => false

# debugging
gem 'pry'

# benchmarking
gem 'benchmark_suite'

# resolve load order issue
gem 'rake'

# used for variable timer modes
gem 'eventmachine'
gem 'em-synchrony'

# Dependency temporarily moved from gemspec until merged:
# https://github.com/librato/librato-metrics/pull/121
gem 'librato-metrics',
  git: 'https://github.com/librato/librato-metrics.git',
  branch: 'feature/md'

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius-developer_tools'
end
