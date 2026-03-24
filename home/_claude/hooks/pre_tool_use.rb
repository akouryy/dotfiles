#!/usr/bin/env ruby
require 'json'

input = JSON.parse($stdin.read)
command = input.dig('tool_input', 'command') || ''

if command.include?('2>/dev/null')
  $stderr.puts 'No ignoring stderr'
  exit 2
end

if command.match?(/\bgit\s+stash\b/)
  $stderr.puts 'git stash is prohibited'
  exit 2
end

if command.match?(/<<\S/)
  $stderr.puts 'Command contains a heredoc. Use a multiline single quote literal instead.'
  exit 2
end

if command.include?('$(')
  $stderr.puts 'Command contains $() command substitution. Use separate commands, pipes, and/or multiline single quote literals.'
  exit 2
end
