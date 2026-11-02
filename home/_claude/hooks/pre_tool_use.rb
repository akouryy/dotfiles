#!/usr/bin/env ruby
require "json"

input = JSON.parse($stdin.read)
tool_name = input["tool_name"]
tool_input = input["tool_input"] || {}
permission_mode = input["permission_mode"]

HOOK_INPUT = input
local_hook = "#{__dir__}/pre_tool_use.local.rb"
load local_hook if File.exist?(local_hook)

case tool_name
when "Bash"
  command = tool_input["command"] || ""

  if command.include?("2>/dev/null")
    $stderr.puts "Never ignore stderr (for example 2>/dev/null)"
    exit 2
  end

  if command.match?(/\brg\s+-r/)
    $stderr.puts "rg -r is prohibited. rg recurses by default, and -r means --replace (not recursive)."
    exit 2
  end

  if command.match?(/(?:^|[;|&({`])\s*g?awk\b/) && !command.include?("--sandbox")
    $stderr.puts "Use `gawk --sandbox` instead of awk/gawk."
    exit 2
  end

  git_write_plumbing_commands = [
    "commit-tree", "fast-import", "filter-branch", "gc", "hash-object", "maintenance", "mktag",
    "mktree", "prune", "prune-packed", "reflog delete", "reflog expire", "repack", "replace",
    "replay", "symbolic-ref", "unpack-objects", "update-index", "update-ref",
    "worktree prune", "worktree remove", "write-tree",
  ]
  if command.match?(/\bgit(?:\s+-\S+)*\s+(?:#{Regexp.union(git_write_plumbing_commands)})\b/)
    $stderr.puts "Write-capable git plumbing commands are prohibited."
    exit 2
  end

  if command.match?(/\bgit\s+stash\b/)
    $stderr.puts "git stash is prohibited"
    exit 2
  end

  if command.match?(/\bgit\s+rebase\b/)
    $stderr.puts "Never rebase. Always merge."
    exit 2
  end

  if command.match?(%r{\bgit\s+add\b[^|&;]*?\s(?:-A|--all|-u|--update|-f|--force|-\w*[Auf]\w*|\.|\./|\*|:/|:\(top\)|'[^']*:\(top\)[^']*'|"[^"]*:\(top\)[^"]*")(?:\s|\z)})
    $stderr.puts "git add with -A/--all/-u/--update/-f/--force/./*/:/ /:(top) is prohibited. Stage files individually by name."
    exit 2
  end

  if command.match?(/\bgit\s+commit\b[^|&;'"]*?\s(?:-a|-[a-zA-Z]*a[a-zA-Z]*|--all)(?:\s|=|\z)/)
    $stderr.puts "git commit -a / --all is prohibited. Stage files individually with git add <file>, then commit."
    exit 2
  end

  if command.match?(/\bgh\s+api\b(?!\s+--method\b)/)
    $stderr.puts "gh api is missing --method. Allowed format: `gh api --method (GET|POST|PATCH|DELETE) --hostname .*`"
    exit 2
  end

  unless permission_mode == "auto"
    if command.match?(/<<\S/)
      $stderr.puts "Command contains a heredoc. Use a multiline single quote literal instead."
      exit 2
    end

    if command.include?("$(")
      $stderr.puts "Command contains $() command substitution. Use separate commands, pipes, and/or multiline single quote literals."
      exit 2
    end

    if command.match?(/\A\w+=/) && !command.match?(/\ARAILS_ENV=test\s/)
      $stderr.puts "Command must not start with a variable assignment."
      exit 2
    end
  end

  minamo = File.expand_path("../../../minamo/target/release/minamo", __dir__)
  if File.executable?(minamo)
    rewritten = command.gsub(/'[^']*'|"(?:\\.|[^"\\])*"|\\.|(?<![|])\|(?![|])(?<sep>&?\s*)(?=(?:grep|head|tail|sed)(?:\s|\z))/) { $~[:sep] ? "|#{$~[:sep]}#{minamo} " : $~[0] }
    if rewritten != command
      puts JSON.generate(hookSpecificOutput: { hookEventName: "PreToolUse", updatedInput: tool_input.merge("command" => rewritten) })
    end
  end

when "Grep", "Glob"
  path = tool_input["path"] || ""

  if path.match?(%r{\A/Users/\w+/\*\*\z})
    $stderr.puts "#{tool_name} path #{path} is too broad. Specify a more specific directory."
    exit 2
  end
end
