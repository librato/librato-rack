$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report('cast') do
    Float('12.2312') rescue false
  end

  x.report('cast fail') do
    Float('22.to.2') rescue false
  end

  x.report('to_s') do
    '12.2312'.to_f.to_s == '12.2312'
  end

  x.report('to_s fail') do
    '22.to.2'.to_f.to_s == '22.to.2'
  end

  x.report('regexp') do
    '12.2312' =~ /^[-+]?[0-9]*\.?[0-9]+$/
  end

  x.report('regexp fail') do
    '22.to.2' =~ /^[-+]?[0-9]*\.?[0-9]+$/
  end
end

# 1.9.3-p448
#
# Calculating -------------------------------------
#                 cast     45855 i/100ms
#            cast fail      5280 i/100ms
#                 to_s     27135 i/100ms
#            to_s fail     32956 i/100ms
#               regexp     35668 i/100ms
#          regexp fail     31669 i/100ms
# -------------------------------------------------
#                 cast  1521837.4 (±6.1%) i/s -    7611930 in   5.025689s
#            cast fail    61125.7 (±4.5%) i/s -     306240 in   5.021445s
#                 to_s   513273.3 (±5.3%) i/s -    2577825 in   5.040703s
#            to_s fail   715552.5 (±5.7%) i/s -    3592204 in   5.040461s
#               regexp  1096181.6 (±5.0%) i/s -    5492872 in   5.026411s
#          regexp fail   654843.6 (±6.7%) i/s -    3261907 in   5.008513s