#!/usr/bin/env zsh


## setup ##

[[ -o interactive ]] || return #interactive only!
zmodload zsh/datetime || { print "can't load zsh/datetime"; return } # faster than date()
autoload -Uz add-zsh-hook || { print "can't add zsh hook!"; return }

(( ${+bgnotify_threshold} )) || bgnotify_threshold=5 #default 10 seconds


## definitions ##

if ! (type bgnotify_formatted | grep -q 'function'); then
  function bgnotify_formatted {
    ## exit_status, command, elapsed_time
    [ $1 -eq 0 ] && title="#win (took $3 s)" || title="#fail (took $3 s)"
    bgnotify "$title" "$2"
  }
fi

currentWindowId () {
  if hash notify-send 2>/dev/null; then #ubuntu!
    xprop -root | awk '/NET_ACTIVE_WINDOW/ { print $5; exit }'
  elif hash osascript 2>/dev/null; then #osx
    osascript -e 'tell application (path to frontmost application as text) to id of front window' 2&> /dev/null || echo "0"
  else
    echo $EPOCHSECONDS #fallback for windows
  fi
}

bgnotify () {
  if hash notify-send 2>/dev/null; then #ubuntu!
    notify-send $1 $2
  elif hash terminal-notifier 2>/dev/null; then #osx
    terminal-notifier -message "$2" -title "$1"
  elif hash growlnotify 2>/dev/null; then #osx growl
    growlnotify -m $1 $2
  elif hash notifu 2>/dev/null; then #cygwyn support!
    notifu /m "$2" /p "$1"
  fi
}


## Zsh hooks ##

bgnotify_begin() {
  bgnotify_timestamp=$EPOCHSECONDS
  bgnotify_lastcmd=$1
  bgnotify_windowid=$(currentWindowId)
}

bgnotify_end() {
  didexit=$?
  elapsed=$(( EPOCHSECONDS - bgnotify_timestamp ))
  past_threshold=$(( elapsed >= bgnotify_threshold ))
  if (( bgnotify_timestamp > 0 )) && (( past_threshold )); then
    if [ $(currentWindowId) != "$bgnotify_windowid" ]; then
      print -n "\a"
      bgnotify_formatted "$didexit" "$bgnotify_lastcmd" "$elapsed"
    fi
  fi
  bgnotify_timestamp=0 #reset it to 0!
}

add-zsh-hook preexec bgnotify_begin
add-zsh-hook precmd bgnotify_end
