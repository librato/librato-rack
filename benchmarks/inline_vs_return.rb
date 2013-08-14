$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'benchmark/ips'

class Demo
  def initialize
    @skip = true
  end

  def do_foo
    return if @skip
    sleep 1
  end

  def always_call
    do_foo
  end

  def call_if
    do_foo if !@skip
  end

  def call_unless
    do_foo unless @skip
  end
end

demo = Demo.new

Benchmark.ips do |x|
  x.report('always_call') do
    demo.always_call
  end

  x.report('call_if') do
    demo.call_if
  end

  x.report('call_unless') do
    demo.call_unless
  end
end
