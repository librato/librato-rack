$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'benchmark/ips'

float = '12.2312'
bad_float = '22.to.2'

Benchmark.ips do |x|
  x.report('cast') do
    Float(float) rescue false
  end

  x.report('cast fail') do
    Float(bad_float) rescue false
  end

  x.report('to_s') do
    float.to_f.to_s == float
  end

  x.report('to_s fail') do
    bad_float.to_f.to_s == bad_float
  end

  x.report('regexp') do
    float =~ /^[-+]?[0-9]*\.?[0-9]+$/
  end

  x.report('regexp fail') do
    bad_float =~ /^[-+]?[0-9]*\.?[0-9]+$/
  end
end

# 1.9.3-p448
#
# Calculating -------------------------------------
#                 cast     47430 i/100ms
#            cast fail      5023 i/100ms
#                 to_s     27435 i/100ms
#            to_s fail     29609 i/100ms
#               regexp     37620 i/100ms
#          regexp fail     32557 i/100ms
# -------------------------------------------------
#                 cast  2283762.5 (±6.8%) i/s -   11383200 in   5.012934s
#            cast fail    63108.8 (±6.7%) i/s -     316449 in   5.038518s
#                 to_s   593069.3 (±8.8%) i/s -    2962980 in   5.042459s
#            to_s fail   857217.1 (±10.0%) i/s -    4263696 in   5.033024s
#               regexp  1383194.8 (±6.7%) i/s -    6884460 in   5.008275s
#          regexp fail   723390.2 (±5.8%) i/s -    3613827 in   5.016494s