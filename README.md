librato-rack
=======

[![Gem Version](https://badge.fury.io/rb/librato-rack.png)](http://badge.fury.io/rb/librato-rack) [![Build Status](https://secure.travis-ci.org/librato/librato-rack.png?branch=master)](http://travis-ci.org/librato/librato-rack) [![Code Climate](https://codeclimate.com/github/librato/librato-rack.png)](https://codeclimate.com/github/librato/librato-rack)

`librato-rack` provides rack middleware which will report key statistics for your rack applications to [Librato Metrics](https://metrics.librato.com/). It will also allow you to easily track your own custom metrics. Metrics are delivered asynchronously behind the scenes so they won't affect performance of your requests.

Currently Ruby 1.9.2+ is required.

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

If you don't have a Metrics account already, [sign up](https://metrics.librato.com/). In order to send measurements to Metrics you need to provide your account credentials to `librato-rack`. You can provide these one of two ways:

##### Use environment variables

By default you can use `LIBRATO_USER` and `LIBRATO_TOKEN` to pass your account data to the middleware. While these are the only required variables, there are a few more optional environment variables you may find useful.

* `LIBRATO_SOURCE` - the default source to use for submitted metrics. If this is not set, hostname of the executing machine will be the default source
* `LIBRATO_PREFIX` - a prefix which will be prepended to all metric names
* `LIBRATO_LOG_LEVEL` - see logging section for more
* `LIBRATO_EVENT_MODE` - use with evented apps, see "Use with EventMachine" below

##### Use a configuration object

If you want to do more complex configuration, use your own environment variables, or control your configuration in code, you can use a configuration object:

    config = Librato::Rack::Configuration.new
    config.user = 'myuser@mysite.com'
    config.token = 'mytoken'
    # …more configuration

    use Librato::Rack, :config => config

See the configuration class for all available options.

##### Running on Heroku

If you are using the [Librato Metrics Heroku addon](https://addons.heroku.com/librato), your `LIBRATO_USER` and `LIBRATO_TOKEN` environment variables will already be set in your Heroku environment. If you are running without the addon you will need to provide them yourself.

You must also specify a custom source for your app to track properly. If an explicit source is not set, `librato-rack` will not start. You can set the source in your environment:

    heroku config:add LIBRATO_SOURCE=myappname

NOTE: if Heroku idles your application no measurements will be sent until it receives another request and is restarted. If you see intermittent gaps in your measurements during periods of low traffic this is the most likely cause.

##### Use with EventMachine and EM Synchrony

`librato-rack` has experimental support for EventMachine and EM Synchrony apps.

When using in an evented context set LIBRATO_EVENT_MODE to `'eventmachine'` if using [EventMachine](https://github.com/eventmachine/eventmachine) or `'synchrony'` if using [EM Synchrony](https://github.com/igrigorik/em-synchrony) and/or [Rack::FiberPool](https://github.com/alebsack/rack-fiber_pool). We're interested in maturing this support, so please let us know if you have any issues.

## Custom Measurements

Tracking anything that interests you is easy with Metrics. There are four primary helpers available:

#### increment

Use for tracking a running total of something _across_ requests, examples:

    # increment the 'sales_completed' metric by one
    Librato.increment 'sales.completed'

    # increment by five
    Librato.increment 'items.purchased', :by => 5

    # increment with a custom source
    Librato.increment 'user.purchases', :source => user.id

Other things you might track this way: user signups, requests of a certain type or to a certain route, total jobs queued or processed, emails sent or received

###### Sporadic Increment Reporting

Note that `increment` is primarily used for tracking the rate of occurrence of some event. Given this increment metrics are _continuous by default_: after being called on a metric once they will report on every interval, reporting zeros for any interval when increment was not called on the metric.

Especially with custom sources you may want the opposite behavior - reporting a measurement only during intervals where `increment` was called on the metric:

    # report a value for 'user.uploaded_file' only during non-zero intervals
    Librato.increment 'user.uploaded_file', :source => user.id, :sporadic => true

#### measure

Use when you want to track an average value _per_-request. Examples:

    Librato.measure 'user.social_graph.nodes', 212

    # report from a custom source
    Librato.measure 'jobs.queued', 3, :source => 'worker.12'

#### timing

Like `Librato.measure` this is per-request, but specialized for timing information:

    Librato.timing 'twitter.lookup.time', 21.2

The block form auto-submits the time it took for its contents to execute as the measurement value:

    Librato.timing 'twitter.lookup.time' do
      @twitter = Twitter.lookup(user)
    end

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

## Cross-Process Aggregation

`librato-rack` submits measurements back to the Librato platform on a _per-process_ basis. By default these measurements are then combined into a single measurement per source (default is your hostname) before persisting the data.

For example if you have 4 hosts with 8 unicorn instances each (i.e. 32 processes total), on the Metrics site you'll find 4 data streams (1 per host) instead of 32.
Current pricing applies after aggregation, so in this case you will be charged for 4 streams instead of 32.

If you want to report per-process instead, you can set `source_pids` to `true` in
your config, which will append the process id to the source name used by each thread.

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

Copyright (c) 2013 [Librato Inc.](http://librato.com) See LICENSE for details.
