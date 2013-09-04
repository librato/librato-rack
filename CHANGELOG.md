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
