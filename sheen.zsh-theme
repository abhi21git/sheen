# Sheen: an animated zsh prompt for macOS. Needs a Nerd Font.

autoload -Uz vcs_info add-zsh-hook add-zle-hook-widget
zmodload zsh/datetime zsh/zselect zsh/system zsh/mathfunc
(( ${+functions[compdef]} )) || { autoload -Uz compinit; compinit -C }

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{208}-- %d --%f'

_sheen_preexec_timer() { _sheen_cmd_start=$SECONDS; _sheen_cmd_name=${1[(w)1]} }
add-zsh-hook preexec _sheen_preexec_timer

_sheen_palette_dawn=(255 179 138  255 214 10  255 111 97  255 143 163)
_sheen_palette_day=(8 148 255  201 89 221  255 46 84  255 144 4)
_sheen_palette_night=(94 92 230  64 200 224  191 90 242  10 132 255)
_sheen_glow=($_sheen_palette_day)
_sheen_tints=(99 230 190  255 122 107  185 166 255  255 194 75  100 210 255  255 111 174  64 200 224  168 224 95)
_sheen_path_rgb=(100 210 255)
_sheen_spinner=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
_sheen_done_at=0 _sheen_morph_at=0 _sheen_cd_at=0 _sheen_vcs_pending_since=0 _sheen_typed_at=0
_sheen_phase=0 _sheen_frame_at=$EPOCHREALTIME _sheen_calm=0 _sheen_sys_checked=0

_sheen_hex() { printf -v REPLY '#%02x%02x%02x' $1 $2 $3 }

_sheen_grad() {
 local u=$(( ($1 % 4.0 + 4.0) % 4.0 ))
 local i=$(( int(u) )) f=$(( u - int(u) ))
 local a=$(( i * 3 + 1 )) z=$(( (i + 1) % 4 * 3 + 1 ))
 reply=(
  $(( int(_sheen_glow[a] + (_sheen_glow[z] - _sheen_glow[a]) * f) ))
  $(( int(_sheen_glow[a+1] + (_sheen_glow[z+1] - _sheen_glow[a+1]) * f) ))
  $(( int(_sheen_glow[a+2] + (_sheen_glow[z+2] - _sheen_glow[a+2]) * f) ))
 )
}

_sheen_set_palette() {
 local h m; strftime -s h %H $EPOCHSECONDS; strftime -s m %M $EPOCHSECONDS
 local t=$(( h * 60 + m )) from to f i
 if (( t >= 360 && t < 660 )); then from=night to=dawn f=$(( (t - 360) / 30.0 ))
 elif (( t >= 660 && t < 1080 )); then from=dawn to=day f=$(( (t - 660) / 30.0 ))
 else from=day to=night f=$(( (t - 1080 + 1440) % 1440 / 30.0 ))
 fi
 (( f > 1 )) && f=1
 local a=(${(P)${:-_sheen_palette_$from}}) b=(${(P)${:-_sheen_palette_$to}})
 _sheen_glow=()
 for (( i = 1; i <= 12; i++ )); do _sheen_glow+=($(( int(a[i] + (b[i] - a[i]) * f) ))); done
}

_sheen_scramble() {
 local o="" c code i
 for (( i = 1; i <= ${#1}; i++ )); do
  c=${1[i]}
  if (( i > $2 )); then
   if [[ $c == [0-9] ]]; then
    c=$(( ($3 + i) % 10 ))
   elif [[ $c == [a-zA-Z] ]]; then
    code=$(( 97 + ($3 + i * 7) % 26 )); c=${(#)code}
   fi
  fi
  o+=$c
 done
 REPLY=$o
}

_sheen_set_tint() {
 if [[ -z $1 ]]; then
  _sheen_path_rgb=(100 210 255)
  return
 fi
 local h=0 i c
 for (( i = 1; i <= ${#1}; i++ )); do
  c=${1[i]}; (( h = (h * 31 + #c) % 65521 ))
 done
 local k=$(( h % 8 * 3 + 1 ))
 _sheen_path_rgb=(${_sheen_tints[k,k+2]})
}

_sheen_check_system() {
 (( EPOCHSECONDS - _sheen_sys_checked < 60 )) && return
 _sheen_sys_checked=$EPOCHSECONDS
 _sheen_calm=0
 [[ $(defaults read com.apple.universalaccess reduceMotion 2>/dev/null) == 1 ]] && _sheen_calm=1
 local lpm=${(M)${(f)"$(pmset -g 2>/dev/null)"}:#*lowpowermode*}
 [[ ${lpm##* } == 1 ]] && _sheen_calm=1
 (( !_sheen_calm != ${+_sheen_fd} )) && _sheen_ticker $(( !_sheen_calm ))
}

_sheen_notify_done() {
 [[ -n $SHEEN_QUIET || -n $SSH_CONNECTION ]] && return
 local title=${_sheen_cmd_name//[^[:alnum:]._-]/}
 {
  afplay /System/Library/Sounds/Glass.aiff &
  [[ ${(L)"$(lsappinfo info -only name "$(lsappinfo front)")"} == *\"${(L)TERM_PROGRAM}\"* ]] ||
   osascript -e "display notification \"Finished in $1\" with title \"$title\""
 } &!
}

_sheen_frame() {
 local now=$EPOCHREALTIME vt=$EPOCHREALTIME i dt e
 (( _sheen_calm )) && vt=0
 dt=$(( now - _sheen_frame_at )); (( dt > 0.2 || dt < 0 )) && dt=0.2
 _sheen_frame_at=$now
 e=$(( 1.0 - (now - _sheen_typed_at) / 1.2 )); (( e < 0 || _sheen_calm )) && e=0
 (( _sheen_phase += dt / 1.2 * (1 + 2 * e) ))

 if (( _sheen_last_exit )); then
  local f=$(( (sin(vt * 3.0) + 1) / 2 ))
  _sheen_hex 255 $(( int(69 + 90 * f) )) $(( int(58 - 48 * f) ))
 elif (( EUID == 0 )); then
  local f=$(( (sin(vt * 5.0) + 1) / 2 ))
  _sheen_hex 255 $(( int(150 + 60 * f) )) $(( int(40 * f) ))
 else
  local k=$(( 0.8 + 0.2 * e )) wm=$(( 0.3 * e ))
  (( _sheen_calm )) && _sheen_grad 0 || _sheen_grad $_sheen_phase
  _sheen_hex $(( int(reply[1] * k * (1 - wm) + 255 * wm) )) $(( int(reply[2] * k * (1 - wm) + 255 * wm) )) $(( int(reply[3] * k * (1 - wm) + 255 * wm) ))
 fi
 _sheen_anim_arrow="%F{$REPLY}❯%f"

 _sheen_hex $_sheen_path_rgb; _sheen_path_hex=$REPLY
 local text=${(%):-%~} out="" ch d t
 if (( !_sheen_calm && now - _sheen_cd_at < 0.45 )); then
  _sheen_scramble $text $(( (now - _sheen_cd_at) / 0.45 * ${#text} )) $(( int(now * 30) ))
  text=$REPLY
 fi
 local n=${#text} w=4.0 sweep=$(( (vt % 4.0) / 0.9 ))
 local pos=$(( sweep * (n + 2 * w) - w ))
 for (( i = 1; i <= n; i++ )); do
  ch=${text[i]}; [[ $ch == % ]] && ch=%%
  d=$(( abs(i - pos) ))
  if (( sweep < 1.0 && d < w )); then
   t=$(( (1 - d / w) * 0.9 ))
   _sheen_hex $(( int(_sheen_path_rgb[1] + (255 - _sheen_path_rgb[1]) * t) )) $(( int(_sheen_path_rgb[2] + (255 - _sheen_path_rgb[2]) * t) )) $(( int(_sheen_path_rgb[3] + (255 - _sheen_path_rgb[3]) * t) ))
   out+="%F{$REPLY}$ch"
  else
   out+="%F{$_sheen_path_hex}$ch"
  fi
 done
 _sheen_anim_path="${out}%f"

 local vcs=$vcs_info_msg_0_
 if (( _sheen_vcs_pending_since && now - _sheen_vcs_pending_since > 0.15 )) && [[ -n $vcs ]]; then
  _sheen_vcs_display="%F{208}${_sheen_spinner[int(now * 12) % 10 + 1]}%f"
 elif (( !_sheen_calm && now - _sheen_morph_at < 0.45 )) && [[ -n $vcs ]]; then
  local plain=${(S)vcs//\%F\{*\}/}
  plain=${plain//\%f/}
  local p=$(( (now - _sheen_morph_at) / 0.45 * ${#plain} ))
  _sheen_scramble $plain $p $(( int(now * 30) ))
  _sheen_vcs_display="%F{208}${REPLY[1,int(p)]}%F{244}${REPLY[int(p)+1,-1]}%f"
 elif [[ $vcs == *↑* ]]; then
  local f=$(( (sin(vt * 2.0) + 1) / 4 + 0.5 ))
  _sheen_hex $(( int(255 * f) )) $(( int(135 * f) )) 0
  local icon="%F{$REPLY}󰘬"
  _sheen_vcs_display=${vcs/\%F\{208\}󰘬/$icon}
 else
  _sheen_vcs_display=$vcs
 fi

 if (( _sheen_done_at )); then
  if (( !_sheen_calm && now - _sheen_done_at < 2.5 )); then
   local msg="took $_sheen_done_fmt" o="" star=✦
   for (( i = 1; i <= ${#msg}; i++ )); do
    _sheen_grad $(( i * 0.35 - now * 3.0 )); _sheen_hex $reply; o+="%F{$REPLY}${msg[i]}"
   done
   (( int(now * 8) % 2 )) && star=✧
   _sheen_elapsed="%F{#ffffff}$star $o %F{#ffffff}$star%f"
  else
   _sheen_elapsed="%F{green}took $_sheen_done_fmt%f"
   _sheen_done_at=0
  fi
 fi

 _sheen_rprompt=$_sheen_elapsed
 [[ -n $_sheen_elapsed && -n $_sheen_vcs_display ]] && _sheen_rprompt+="%F{238} · %f"
 _sheen_rprompt+=$_sheen_vcs_display
}

_sheen_tick() {
 sysread -i $1 -s 4096 _ 2>/dev/null
 [[ $_sheen_real_widget == *(complete|incremental-search|menu-select)* ]] && return
 _sheen_frame
 zle reset-prompt
}
zle -N _sheen_tick

_sheen_ticker() {
 if (( ${+_sheen_fd} )); then
  zle -F $_sheen_fd 2>/dev/null
  exec {_sheen_fd}<&-
  unset _sheen_fd
 fi
 (( $1 )) || return
 exec {_sheen_fd}< <(while :; do zselect -t 6; print || exit; done)
 zle -F -w $_sheen_fd _sheen_tick
}
_sheen_ticker 1

_sheen_chpwd() { _sheen_cd_at=$EPOCHREALTIME }
add-zsh-hook chpwd _sheen_chpwd

_sheen_track_keys() {
 [[ $LASTWIDGET != _sheen_tick ]] && _sheen_real_widget=$LASTWIDGET
 [[ "$CURSOR:$BUFFER" == "$_sheen_last_buf" ]] && return
 _sheen_last_buf="$CURSOR:$BUFFER"
 _sheen_typed_at=$EPOCHREALTIME
}
add-zle-hook-widget line-pre-redraw _sheen_track_keys

_sheen_vcs_tmp="${TMPDIR:-/tmp}/zsh-vcs-$$"

_sheen_vcs_job=0

_sheen_async_vcs_run() {
 _sheen_vcs_pending_since=$EPOCHREALTIME
 local out="$_sheen_vcs_tmp.$(( ++_sheen_vcs_job ))"
 {
  vcs_info sheen
  print -rn -- "$vcs_info_msg_0_"$'\n'"$vcs_info_msg_1_" >! $out
  kill -USR1 $$ 2>/dev/null
 } &!
}

TRAPUSR1() {
 if [[ -r $_sheen_vcs_tmp.$_sheen_vcs_job ]]; then
  local data="$(<$_sheen_vcs_tmp.$_sheen_vcs_job)"
  rm -f $_sheen_vcs_tmp.*(N)
  local msg=${data%%$'\n'*}
  [[ -n $msg && $msg != $vcs_info_msg_0_ ]] && _sheen_morph_at=$EPOCHREALTIME
  vcs_info_msg_0_=$msg
  _sheen_set_tint ${data#*$'\n'}
  _sheen_vcs_pending_since=0
  _sheen_frame
  zle && zle reset-prompt
 fi
}

_sheen_vcs_cleanup() { rm -f $_sheen_vcs_tmp.*(N) }
add-zsh-hook zshexit _sheen_vcs_cleanup

_sheen_precmd_prompt() {
 local last_exit=$?
 _sheen_last_exit=$last_exit
 PROMPT=$_sheen_full_prompt
 _sheen_last_buf="0:"
 _sheen_done_at=0
 _sheen_check_system
 _sheen_set_palette
 _sheen_async_vcs_run
 _sheen_elapsed=""
 if [[ -n $_sheen_cmd_start ]]; then
  local elapsed=$(( SECONDS - _sheen_cmd_start ))
  if (( elapsed >= 1 )); then
   local fmt
   if (( elapsed >= 60 )); then
    fmt="$(( elapsed / 60 ))m $(( elapsed % 60 ))s"
   else
    fmt="${elapsed}s"
   fi
   _sheen_elapsed="%F{green}took ${fmt}%f"
   if (( elapsed >= 10 )); then
    _sheen_done_at=$EPOCHREALTIME _sheen_done_fmt=$fmt
    _sheen_notify_done $fmt
   fi
  fi
  unset _sheen_cmd_start
 fi
 if (( last_exit != 0 )); then
  local code=$last_exit
  (( last_exit > 128 && last_exit - 127 <= ${#signals} )) && code=${signals[last_exit-127]}
  _sheen_exit="%F{red}× ${code}%f "
 else
  _sheen_exit=""
 fi
 _sheen_frame
}
add-zsh-hook precmd _sheen_precmd_prompt
setopt prompt_subst transient_rprompt

+vi-sheen-git-st() {
 [[ $1 == 0 ]] || return 0
 local line ahead=0 behind=0 s=0 u=0 un=0
 for line in "${(@f)$(git status --porcelain=v2 --branch 2>/dev/null)}"; do
  case $line in
   '# branch.ab '*) ahead=${${(s: :)line}[3]#+}; behind=${${(s: :)line}[4]#-} ;;
   [12]' '*) [[ ${line[3]} != . ]] && (( s++ )); [[ ${line[4]} != . ]] && (( u++ )) ;;
   'u '*) (( u++ )) ;;
   '? '*) (( un++ )) ;;
  esac
 done

 local ab=""
 (( ahead > 0 )) && ab+=" %F{cyan}↑${ahead}%f"
 (( behind > 0 )) && ab+=" %F{yellow}↓${behind}%f"

 local parts=()
 (( s > 0 )) && parts+=("%F{green}+${s}%f")
 (( u > 0 )) && parts+=("%F{red}!${u}%f")
 (( un > 0 )) && parts+=("%F{244}?${un}%f")

 local status_block=""
 if (( ${#parts} > 0 )); then
  status_block=" %F{244}status %F{208}[%f${(j: :)parts}%F{208}]%f"
 fi

 hook_com[misc]="${ab}${status_block}"
}

zstyle ':vcs_info:*:sheen:*' enable git
zstyle ':vcs_info:git+set-message:sheen:*' hooks sheen-git-st
zstyle ':vcs_info:git:sheen:*' formats '%F{208}󰘬 %b%f%m' '%r'
zstyle ':vcs_info:git:sheen:*' actionformats '%F{208}󰘬 %b|%a%f%m' '%r'

[[ -n $SSH_CONNECTION ]] && _sheen_host='%F{244}%n@%m%f '
_sheen_full_prompt=$'${_sheen_host}%F{${_sheen_path_hex}}󰉋 ${_sheen_anim_path}\n${_sheen_exit}${_sheen_anim_arrow} '
PROMPT=$_sheen_full_prompt
RPROMPT='${_sheen_rprompt}'

_sheen_transient_prompt() { PROMPT='%F{244}%1~ ❯%f '; _sheen_rprompt=; zle .reset-prompt }
add-zle-hook-widget line-finish _sheen_transient_prompt
