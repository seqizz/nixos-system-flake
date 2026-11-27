#compdef sysman

# System generation numbers, each described by the time it was built.
_sysman_generation_numbers() {
  local -a generations
  local link number built
  zmodload -F zsh/stat b:zstat 2>/dev/null
  for link in /nix/var/nix/profiles/system-<->-link(Nn); do
    number=${${link:t}#system-}
    number=${number%-link}
    built=$(zstat -L -F '%Y-%m-%d %H:%M' +mtime -- $link 2>/dev/null)
    generations+=("${number}:${built}")
  done
  # -V keeps the numeric order of the glob.
  _describe -V -t generations 'generation' generations
}

# sysman diff takes a generation number or any path nvd can compare.
_sysman_generations() {
  _alternative \
    'generations:generation:_sysman_generation_numbers' \
    'paths:path:_files -/'
}

_sysman() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '(- *)'{-h,--help}'[show help]' \
    '1: :->command' \
    '*:: :->args'

  case $state in
    command)
      local -a commands=(
        'up:update flake inputs, rebuild and activate, staying in the live profile'
        'status:live profile, running system, generations and failed units'
        'diff:package diff between two system generations'
        'clean:drop old generations, collect garbage, optimise the store'
      )
      # The marker exists only on machines with the work specialisation, the
      # same ones where sysman has the subcommand.
      if [[ -e /etc/nixos-profile ]]; then
        commands+=('work:switch the work profile on or off at runtime, no rebuild')
      fi
      _describe -t commands 'sysman command' commands
      ;;
    args)
      case $words[1] in
        up)
          _arguments \
            '(- *)'{-h,--help}'[show help]' \
            '--no-update[rebuild without updating flake inputs]'
          ;;
        work)
          _arguments '1::state:(on off)'
          ;;
        diff)
          _arguments \
            '1:old generation:_sysman_generations' \
            '2:new generation:_sysman_generations'
          ;;
      esac
      ;;
  esac
}

_sysman "$@"
