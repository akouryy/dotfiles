#!/usr/bin/env ruby
require 'json'

input = JSON.parse($stdin.read)
command = input.dig('tool_input', 'command') || ''

if command.include?('2>/dev/null')
  $stderr.puts 'Never ignore stderr'
  exit 2
end

if command.match?(/\bgh\s+api\b/) && !command.match?(/\bgh\s+api\s+--method\s+\S+/)
  $stderr.puts 'gh api must be followed by --method <VERB>'
  exit 2
end

if (m = command.match(/\bgit\s+(stash|checkout|restore|reset)\b/))
  $stderr.puts "git #{m[1]} is strictly prohibited"
  exit 2
end

#if command.match?(/<<\S/)
#  $stderr.puts 'Command contains a heredoc. Use a multiline single quote literal instead.'
#  exit 2
#end

if command.match?(/\b(?:ruby|perl)\b/) && command.split(/\s+/).any? { |token| token.match?(/\A-[a-zA-Z]*p/) }
  $stderr.puts 'The -p option of ruby/perl is prohibited: `next` skips its implicit print and silently deletes every non-matching line. Read the file, edit it, and write it back instead.'
  exit 2
end

minamo = File.expand_path("../../../minamo/target/release/minamo", __dir__)
if File.executable?(minamo)
  rewritten = command.gsub(/'[^']*'|"(?:\\.|[^"\\])*"|\\.|(?<![|])\|(?![|])(?<sep>&?\s*)(?=(?:grep|head|tail|sed)(?:\s|\z))/) { $~[:sep] ? "|#{$~[:sep]}#{minamo} " : $~[0] }
  if rewritten != command
    puts JSON.generate(hookSpecificOutput: { hookEventName: "PreToolUse", updatedInput: (input["tool_input"] || {}).merge("command" => rewritten) })
  end
end
