require 'holidays'
require 'date'

first = Date.parse(ARGV[0])
last  = Date.parse(ARGV[1])

(first..last).each do |date|
  puts date if date.holiday?(:jp)
end
