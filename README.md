librato-rack
=======

[![Gem Version](https://badge.fury.io/rb/librato-rack.png)](http://badge.fury.io/rb/librato-rack) [![Build Status](https://secure.travis-ci.org/librato/librato-rack.png?branch=master)](http://travis-ci.org/librato/librato-rack) [![Code Climate](https://codeclimate.com/github/librato/librato-rack.png)](https://codeclimate.com/github/librato/librato-rack)

`librato-rack` provides rack middleware which will report key statistics for your rack applications to [Librato Metrics](https://metrics.librato.com/). It will also allow you to easily track your own custom metrics. Metrics are delivered asynchronously behind the scenes so they won't affect performance of your requests.

Currently Ruby 1.9.2+ is required.

## Upgrading

Upgrading from version 1.x to 2.x introduces breaking changes for legacy sources. Please contact [support@librato.com](mailto:support@librato.com) to migrate an existing Librato account.

## Quick Start

Install `librato-rack` as middleware in your application:

    use Librato::Rack

Configuring and relaunching your application will start the reporting of performance and request metrics. You can also track custom metrics by adding simple one-liners to your code:

    # keep counts of key events
    Librato.increment 'user.signup'

    # benchmark sections of code to verify production performance
    Librato.timing 'my.complicated.work' do
      # do work
    end

    # track averages across requests
    Librato.measure 'user.social_graph.nodes', user.social_graph.size

## Installation & Configuration

Install the gem:

    $ gem install librato-rack

Or add to your Gemfile if using bundler:

    gem "librato-rack"

In your rackup file or equivalent, require and add the middleware:

    require 'librato-rack'
    use Librato::Rack

In order to get the most accurate measurements, it is recommended that the `librato-rack` middleware be the first middleware in your stack. This will ensure that timing measurements like the `rack.request.time` metric will include all of the time spent in the Rack middleware stack.

If you don't have a Metrics account already, [sign up](https://metrics.librato.com/). In order to send measurements to Metrics you need to provide your account credentials to `librato-rack`. You can provide these one of two ways:

##### Use environment variables

By default you can use `LIBRATO_USER` and `LIBRATO_TOKEN` to pass your account data to the middleware. While these are the only required variables, there are a few more optional environment variables you may find useful.

* `LIBRATO_TAGS` - the default tags to use for submitted metrics. Format is comma-separated key=value pairs, e.g. `region=us-east,az=b`. If not set, `host` of the executing machine is detected and set as default tag
* `LIBRATO_SUITES` - manage which metrics librato-rack will report. See more in [metrics suites](#metric-suites).
* `LIBRATO_PREFIX` - a prefix which will be prepended to all metric names
* `LIBRATO_LOG_LEVEL` - see logging section for more
* `LIBRATO_PROXY` - HTTP proxy to use when connecting to the Librato API (can also use the `https_proxy` or `http_proxy` environment variable commonly supported by Linux command line utilities)
* `LIBRATO_AUTORUN` - set to `'0'` to prevent the reporter from starting, useful if you don't want `librato-rack` to start under certain circumstances
* `LIBRATO_EVENT_MODE` - use with evented apps, see "Use with EventMachine" below

##### Use a configuration object

If you want to do more complex configuration, use your own environment variables, or control your configuration in code, you can use a configuration object:

    config = Librato::Rack::Configuration.new
    config.user = 'myuser@mysite.com'
    config.token = 'mytoken'
    # …more configuration

    use Librato::Rack, :config => config

See the [configuration class](https://github.com/librato/librato-rack/blob/master/lib/librato/rack/configuration.rb) for all available options.

##### Running on Heroku

If you are using the [Librato Metrics Heroku addon](https://addons.heroku.com/librato), your `LIBRATO_USER` and `LIBRATO_TOKEN` environment variables will already be set in your Heroku environment. If you are running without the addon you will need to provide them yourself.

NOTE: if Heroku idles your application no measurements will be sent until it receives another request and is restarted. If you see intermittent gaps in your measurements during periods of low traffic this is the most likely cause.

## Default Tags

Librato Metrics supports tagged measurements that are associated with a metric, one or more tag pairs, and a point in time. For more information on tagged measurements, visit our [API documentation](https://www.librato.com/docs/api/#measurements).

##### Detected Tags

By default, `host` is detected and applied as a default tag for submitted measurements. Optionally, you can override the detected values, e.g. `LIBRATO_TAGS=host=myapp-prod-1`

##### Custom Tags

In addition to the default tags, you can also provide custom tags:

```ruby
config = Librato::Rack::Configuration.new
config.user = 'myuser@mysite.com'
config.token = 'mytoken'
config.tags = { service: 'myapp', environment: 'production', host: 'myapp-prod-1' }

use Librato::Rack, :config => config
```

##### Metric Suites

The metrics recorded by `librato-rack` are organized into named metric suites that can be selectively enabled/disabled:

* `rack`: The `rack.request.total`, `rack.request.time`, `rack.request.slow`, and `rack.request.queue.time` metrics
* `rack_status`: `rack.request.status` metric with `status` tag name and HTTP status code tag value, e.g. `status=200`
* `rack_method`: `rack.request.method` metric with `method` tag name and HTTP method tag value, e.g. `method=POST`

All three of the metric suites listed above are enabled by default.

The metric suites can be configured via either the `LIBRATO_SUITES` environment variable or the `suites` attributes on the `Librato::Rack::Configuration` object.

    LIBRATO_SUITES="rack,rack_method"  # use ONLY the rack and rack_method suites
    LIBRATO_SUITES="+foo,+bar"         # + prefix indicates that you want the default suites plus foo and bar
    LIBRATO_SUITES="-rack_status"      # - prefix indicates that you want the default suites removing rack_status
    LIBRATO_SUITES="+foo,-rack_status" # Use all default suites except for rack_status while also adding foo
    LIBRATO_SUITES="all"               # Enable all suites
    LIBRATO_SUITES="none"              # Disable all suites
    LIBRATO_SUITES=""                  # Use only the default suites (same as if env var is absent)

Note that you should EITHER specify an explict list of suites to enable OR add/subtract individual suites from the default list (using the +/- prefixes). If you try to mix these two forms a `Librato::Rack::InvalidSuiteConfiguration` error will be raised.

##### Use with EventMachine and EM Synchrony

`librato-rack` has experimental support for EventMachine and EM Synchrony apps.

When using in an evented context set LIBRATO_EVENT_MODE to `'eventmachine'` if using [EventMachine](https://github.com/eventmachine/eventmachine) or `'synchrony'` if using [EM Synchrony](https://github.com/igrigorik/em-synchrony) and/or [Rack::FiberPool](https://github.com/alebsack/rack-fiber_pool). We're interested in maturing this support, so please let us know if you have any issues.

## Custom Measurements

Tracking anything that interests you is easy with Metrics. There are four primary helpers available:

#### increment

Use for tracking a running total of something _across_ requests, examples:

```ruby
# increment the 'sales_completed' metric by one
Librato.increment 'sales.completed'
# => {:host=>"myapp-prod-1"}

# increment by five
Librato.increment 'items.purchased', by: 5
# => {:host=>"myapp-prod-1"}

# increment with custom per-measurement tags
Librato.increment 'user.purchases', tags: { user_id: user.id, currency: 'USD' }
# => {:user_id=>43, :currency=>"USD"}

# increment with custom per-measurement tags and inherited default tags
Librato.increment 'user.purchases', tags: { user_id: user.id, currency: 'USD' }, inherit_tags: true
# => {:host=>"myapp-prod-1", :user_id=>43, :currency=>"USD"}
```

Other things you might track this way: user signups, requests of a certain type or to a certain route, total jobs queued or processed, emails sent or received

###### Sporadic Increment Reporting

Note that `increment` is primarily used for tracking the rate of occurrence of some event. Given this increment metrics are _continuous by default_: after being called on a metric once they will report on every interval, reporting zeros for any interval when increment was not called on the metric.

Especially with custom per-measurement tags you may want the opposite behavior - reporting a measurement only during intervals where `increment` was called on the metric:

```ruby
# report a value for 'user.uploaded_file' only during non-zero intervals
Librato.increment 'user.uploaded_file', tags: { user_id: user.id, bucket: bucket.name }, sporadic: true
```

#### measure

Use when you want to track an average value _per_-request. Examples:

    Librato.measure 'user.social_graph.nodes', 212

    # report from custom per-measurement tags
    Librato.measure 'jobs.queued', 3, tags: { priority: 'high', worker: 'worker.12' }

#### timing

Like `Librato.measure` this is per-request, but specialized for timing information:

    Librato.timing 'twitter.lookup.time', 21.2

The block form auto-submits the time it took for its contents to execute as the measurement value:

    Librato.timing 'twitter.lookup.time' do
      @twitter = Twitter.lookup(user)
    end

#### percentiles

By defaults timings will send the average, sum, max and min for every minute. If you want to send percentiles as well you can specify them inline while instrumenting:

```ruby
# track a single percentile
Librato.timing 'api.request.time', time, percentile: 95

# track multiple percentiles
Librato.timing 'api.request.time', time, percentile: [95, 99]
```

You can also use percentiles with the block form of timings:

```ruby
Librato.timing 'my.important.event', percentile: 95 do
  # do work
end
```

#### group

There is also a grouping helper, to make managing nested metrics easier. So this:

    Librato.measure 'memcached.gets', 20
    Librato.measure 'memcached.sets', 2
    Librato.measure 'memcached.hits', 18

Can also be written as:

    Librato.group 'memcached' do |g|
      g.measure 'gets', 20
      g.measure 'sets', 2
      g.measure 'hits', 18
    end

Symbols can be used interchangeably with strings for metric names.

## Use with Background Workers / Cron Jobs

`librato-rack` is designed to run within a long-running process and report periodically. Intermittently running rake tasks and most background job tools (delayed job, resque, queue_classic) don't run long enough for this to work.

Never fear, [we have some guidelines](https://github.com/librato/librato-rails/wiki/Monitoring-Background-Workers) for how to instrument your workers properly.

If you are using `librato-rack` with sidekiq, [see these notes about setup](https://github.com/librato/librato-rails/wiki/Monitoring-Background-Workers#monitoring-long-running-threaded-workers-sidekiq-etc).

## Cross-Process Aggregation

`librato-rack` submits measurements back to the Librato platform on a _per-process_ basis. By default these measurements are then combined into a single measurement per default tags (detects `host`) before persisting the data.

For example if you have 4 hosts with 8 unicorn instances each (i.e. 32 processes total), on the Metrics site you'll find 4 data streams (1 per host) instead of 32.
Current pricing applies after aggregation, so in this case you will be charged for 4 streams instead of 32.

## Troubleshooting

Note that it may take 2-3 minutes for the first results to show up in your Metrics account after you have started your servers with `librato-rack` enabled and the first request has been received.

For more information about startup and submissions to the Metrics service you can set your `log_level` to `debug`. If you are having an issue with a specific metric, using `trace` will add the exact measurements being sent to your logs along with other details about `librato-rack` execution. Neither of these modes are recommended long-term in production as they will add significant volume to your log file and may slow operation somewhat.

Submission times are total time but submission I/O is non-blocking - your process will continue to handle requests during submissions.

If you are debugging setup locally you can set `flush_interval` to something shorter (say 10s) to force submission more frequently. Don't change your `flush_interval` in production as it will not result in measurements showing up more quickly, but may affect performance.

## Contribution

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project and submit a pull request from a feature or bugfix branch.
* Please include tests. This is important so we don't break your changes unintentionally in a future version.
* Please don't modify the gemspec, Rakefile, version, or changelog. If you do change these files, please isolate a separate commit so we can cherry-pick around it.

## Copyright

Copyright (c) 2013-2017 [Librato Inc.](http://librato.com) See LICENSE for details.
