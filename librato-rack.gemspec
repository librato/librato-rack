$:.push File.expand_path("../lib", __FILE__)

require "librato/rack/version"

Gem::Specification.new do |s|
  s.name        = "librato-rack"
  s.version     = Librato::Rack::VERSION

  s.authors     = ["Matt Sanders"]
  s.email       = ["matt@librato.com"]
  s.homepage    = "https://github.com/librato/librato-rack"

  s.summary     = "Use Librato Metrics with your rack application"
  s.description = "Rack middleware to report key app statistics and custom instrumentation to the Librato Metrics service."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "librato-metrics", "~> 1.0.2"
  s.add_development_dependency "minitest"
end
