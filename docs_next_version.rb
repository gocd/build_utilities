#!/usr/bin/env ruby

require 'date'

def validate(key)
  value = ENV[key].to_s.strip
  fail "Please specify #{key}" if value == ''
  fail "Specify a valid version" unless value =~ /\d+\.\d+\.\d+/
  value
end

version_to_release = validate('VERSION_TO_RELEASE')
segments_of_version_to_release = Gem::Version.new(version_to_release).segments

# The below if logic is only for December and the assumption is we make one release at that time of the year. We can revisit if we make more than one release in December.

if (Date.today() + 31).strftime('%y') == segments_of_version_to_release[0].to_s
  next_version = [segments_of_version_to_release[0], segments_of_version_to_release[1] + 1, 0].join('.')
else
  next_version = [(Date.today() + 31).strftime('%y'), 1, 0].join('.')
end

File.open('version', 'w') { |file| file.write("export NEXT_VERSION=#{next_version}") }

