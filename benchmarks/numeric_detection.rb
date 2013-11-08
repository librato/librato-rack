$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report('cast') do
    Integer('220000') rescue false
  end

  x.report('cast fail') do
    Integer('22.to.2') rescue false
  end

  x.report('to_s') do
    '220000'.to_i.to_s == '220000'
  end

  x.report('to_s fail') do
    '22.to.2'.to_i.to_s == '22.to.2'
  end

  x.report('regexp') do
    '220000' =~ /^\d$/i
  end

  x.report('regexp fail') do
    '22.to.2' =~ /^\d$/i
  end
end

# 1.9.3-p448
#
# Calculating -------------------------------------
#                 cast     48017 i/100ms
#            cast fail      5363 i/100ms
#                 to_s     39235 i/100ms
#            to_s fail     41486 i/100ms
#               regexp     37937 i/100ms
#          regexp fail     38387 i/100ms
# -------------------------------------------------
#                 cast  1772621.4 (±6.2%) i/s -    8835128 in   5.007432s
#            cast fail    62209.7 (±3.8%) i/s -     311054 in   5.008219s
#                 to_s   926607.6 (±6.7%) i/s -    4629730 in   5.023931s
#            to_s fail  1064134.2 (±5.4%) i/s -    5310208 in   5.007077s
#               regexp  1083470.1 (±6.0%) i/s -    5424991 in   5.030486s
#          regexp fail  1125308.8 (±6.8%) i/s -    5604502 in   5.011036s