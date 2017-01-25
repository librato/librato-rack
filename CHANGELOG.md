### master
* Add support for tagged measurements (#54)

### Version 1.1.0
* Fix deprecation warnings in ruby 2.4 (#57, Ben Radler)

### Version 1.0.1
* Fix missing p95 for rack.request.time

### Version 1.0.0
* Add support for configurable metric suites
* Drop support for long-deprecated config via LIBRATO_METRICS_* env vars
* Drop support for old-style config passing during initialization
* Deprecate `disable_rack_metrics` config option, use `suites='none'` instead

### Version 0.6.0
* Add support for proxy configuration

### Version 0.5.0
* Add support for percentiles when timing
* Report p95 for rack.request.time and rack.request.queue.time

### Version 0.4.5
* Add #start! to tracker

### Version 0.4.4
* Relax version constraint for librato-metrics

### Version 0.4.3
* Update queue wait support to tolerate float-style timestamps

### Version 0.4.2
* Move gem sign code to rake task, fixes bug bundling in some environments

### Version 0.4.1
* Support a pre-configured tracker object
* Make log-prefix configurable
* Break pid-locking out of startup checks

### Version 0.4.0
* Add HTTP method (GET, POST) metrics
* Add log buffering support
* Ensure all options passed to a grouped increment are respected
* LIBRATO_AUTORUN can be used to prevent startup
* Add ability to interrupt reporter process
* Start reporting deprecations for old config methods
* Add docs for best practices for background workers
* Other documentation improvements

### Version 0.3.0
* Add experimental support for EventMachine and EMSynchrony (Balwant K)
* Start testing suite against jruby/rbx
* Gem is now signed

### Version 0.2.1
* Fix exception if logging metrics before middleware init (Eric Holmes)

### Version 0.2.0
* Add disable_rack_metrics config option
* Remove metrics based on deprecated heroku HTTP headers
* Ensure compatibility with ruby 2.0

### Version 0.1.0
* Initial version
