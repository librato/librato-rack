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
    '220000' =~ /^\d+$/
  end

  x.report('regexp fail') do
    '22.to.2' =~ /^\d+$/
  end
end

# 1.9.3-p448
#
# Calculating -------------------------------------
#                 cast     49057 i/100ms
#            cast fail      5077 i/100ms
#                 to_s     38512 i/100ms
#            to_s fail     40598 i/100ms
#               regexp     39031 i/100ms
#          regexp fail     35803 i/100ms
# -------------------------------------------------
#                 cast  1769753.6 (±5.4%) i/s -    8830260 in   5.008356s
#            cast fail    59323.0 (±7.5%) i/s -     299543 in   5.081630s
#                 to_s   910725.9 (±6.2%) i/s -    4544416 in   5.012002s
#            to_s fail  1061915.4 (±4.8%) i/s -    5318338 in   5.022866s
#               regexp  1171096.1 (±7.6%) i/s -    5815619 in   5.005146s
#          regexp fail  1001235.6 (±5.3%) i/s -    5012420 in   5.024768s