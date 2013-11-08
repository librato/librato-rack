$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'benchmark/ips'

int = '220000'
bad_int = '22.to.2'

Benchmark.ips do |x|
  x.report('cast') do
    Integer(int) rescue false
  end

  x.report('cast fail') do
    Integer(bad_int) rescue false
  end

  x.report('to_s') do
    int.to_i.to_s == int
  end

  x.report('to_s fail') do
    bad_int.to_i.to_s == bad_int
  end

  x.report('regexp') do
    int =~ /^\d+$/
  end

  x.report('regexp fail') do
    bad_int =~ /^\d+$/
  end
end

# 1.9.3-p448
#
# Calculating -------------------------------------
#                 cast     57485 i/100ms
#            cast fail      5549 i/100ms
#                 to_s     47509 i/100ms
#            to_s fail     50573 i/100ms
#               regexp     45187 i/100ms
#          regexp fail     42566 i/100ms
# -------------------------------------------------
#                 cast  2353703.4 (±4.9%) i/s -   11726940 in   4.998270s
#            cast fail    65590.2 (±4.6%) i/s -     327391 in   5.003511s
#                 to_s  1420892.0 (±6.8%) i/s -    7078841 in   5.011462s
#            to_s fail  1717948.8 (±6.0%) i/s -    8546837 in   4.998672s
#               regexp  1525729.9 (±7.0%) i/s -    7591416 in   5.007105s
#          regexp fail  1154461.1 (±5.5%) i/s -    5788976 in   5.035311s