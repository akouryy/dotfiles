#!/usr/bin/env ruby
require 'json'

input = JSON.parse($stdin.read)
command = input.dig('tool_input', 'command') || ''

if command.include?('2>/dev/null')
  $stderr.puts 'No ignoring stderr'
  exit 2
end
