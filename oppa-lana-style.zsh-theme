function prompt_char {
    git branch >/dev/null 2>/dev/null && echo '○' && return
    echo '○'
}

function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

: ${omg_ungit_prompt:=$PS1}
: ${omg_second_line:="╰──$(virtualenv_info)$(prompt_char) %~ • "}
: ${omg_is_a_git_repo_symbol:=''}
: ${omg_has_untracked_files_symbol:=''}        #                ?    
: ${omg_has_adds_symbol:=''}
: ${omg_has_deletions_symbol:=''}
: ${omg_has_cached_deletions_symbol:=''}
: ${omg_has_modifications_symbol:=''}
: ${omg_has_cached_modifications_symbol:=''}
: ${omg_ready_to_commit_symbol:=''}            #   →
: ${omg_is_on_a_tag_symbol:=''}                #   
: ${omg_needs_to_merge_symbol:='ᄉ'}
: ${omg_detached_symbol:=''}
: ${omg_can_fast_forward_symbol:=''}
: ${omg_has_diverged_symbol:=''}               #   
: ${omg_not_tracked_branch_symbol:=''}
: ${omg_rebase_tracking_branch_symbol:=''}     #   
: ${omg_merge_tracking_branch_symbol:=''}      #  
: ${omg_should_push_symbol:=''}                #    
: ${omg_has_stashes_symbol:=''}
: ${omg_has_action_in_progress_symbol:=''}     #                  

autoload -U colors && colors

PROMPT='$(build_prompt)'
RPROMPT='%{%K{default}%}%{%F{white}%}%{%K{white}%}%{%F{black}%} %{%F{magenta}%}%n% %{%F{cyan}%}@%{%F{magenta}%}%m%  %{%K{white}%}%{%F{black}%}%{%K{black}%}%{$FG[040]%} ⌚ %*%  %{$reset_color%}'

## Main prompt
default_build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_dir  
  prompt_end
}

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  symbols+="%{%F{white}%} "
  prompt_segment black default "$symbols"

}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    prompt_segment white black "(`basename $virtualenv_path`)"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment white black '%~'
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}
╰──$(prompt_char) • "
  CURRENT_BG=''
}

function enrich_append {
    local flag=$1
    local symbol=$2
    local color=${3:-$omg_default_color_on}
    if [[ $flag == false ]]; then symbol=' '; fi

    echo -n "${color}${symbol}  "
}

function custom_build_prompt {
    local enabled=${1}
    local current_commit_hash=${2}
    local is_a_git_repo=${3}
    local current_branch=$4
    local detached=${5}
    local just_init=${6}
    local has_upstream=${7}
    local has_modifications=${8}
    local has_modifications_cached=${9}
    local has_adds=${10}
    local has_deletions=${11}
    local has_deletions_cached=${12}
    local has_untracked_files=${13}
    local ready_to_commit=${14}
    local tag_at_current_commit=${15}
    local is_on_a_tag=${16}
    local has_upstream=${17}
    local commits_ahead=${18}
    local commits_behind=${19}
    local has_diverged=${20}
    local should_push=${21}
    local will_rebase=${22}
    local has_stashes=${23}
    local action=${24}

    local prompt=""
    local original_prompt=$PS1


    local black_on_white="%K{white}%F{black}"
    local yellow_on_white="%K{white}%F{yellow}"
    local red_on_white="%K{white}%F{red}"
    local red_on_black="%K{black}%F{red}"
    local black_on_green="%K{green}%F{black}"
    local white_on_green="%K{green}%F{white}"
    local white_on_yellow="%K{yellow}%F{white}"
    local white_on_black="%K{black}%F{white}"
    local yellow_on_green="%K{green}%F{yellow}"
 
    # Flags
    local omg_default_color_on="${black_on_white}"

    local current_path="%~"

    if [[ $is_a_git_repo == true ]]; then
        # on filesystem

        prompt="${white_on_black} "
        prompt+=$(enrich_append $is_a_git_repo $omg_is_a_git_repo_symbol "${white_on_black}")
        prompt+=$(enrich_append $is_a_git_repo $SEGMENT_SEPARATOR "${black_on_white}")
        prompt+=$(enrich_append $has_stashes $omg_has_stashes_symbol "${yellow_on_white}")

        prompt+=$(enrich_append $has_untracked_files $omg_has_untracked_files_symbol "${red_on_white}")
        prompt+=$(enrich_append $has_modifications $omg_has_modifications_symbol "${red_on_white}")
        prompt+=$(enrich_append $has_deletions $omg_has_deletions_symbol "${red_on_white}")
        

        # ready
        prompt+=$(enrich_append $has_adds $omg_has_adds_symbol "${black_on_white}")
        prompt+=$(enrich_append $has_modifications_cached $omg_has_cached_modifications_symbol "${black_on_white}")
        prompt+=$(enrich_append $has_deletions_cached $omg_has_cached_deletions_symbol "${black_on_white}")
        
        # next operation

        prompt+=$(enrich_append $ready_to_commit $omg_ready_to_commit_symbol "${red_on_white}")
        prompt+=$(enrich_append $action "${omg_has_action_in_progress_symbol} $action" "${red_on_white}")

        # where

        git_status_bg=${white_on_green}
        git_status_color="green"
        if [[ $has_untracked_files == true || $has_modifications == true || $has_deletions == true || $has_adds == true || $has_modifications_cached == true || $ready_to_commit == true || $action == true ]]; then
	    git_status_bg=${white_on_yellow}
            git_status_color="yellow"
        fi

        prompt="${prompt} ${git_clean} ${git_status_bg} ${git_status_bg}"
        if [[ $detached == true ]]; then
            prompt+=$(enrich_append $detached $omg_detached_symbol "${git_status_bg}")
            prompt+=$(enrich_append $detached "(${current_commit_hash:0:7})" "${git_status_bg}")
        else            
            if [[ $has_upstream == false ]]; then
                prompt+=$(enrich_append true "-- ${omg_not_tracked_branch_symbol}  --  (${current_branch})" "${git_status_bg}")
            else
                if [[ $will_rebase == true ]]; then
                    local type_of_upstream=$omg_rebase_tracking_branch_symbol
                else
                    local type_of_upstream=$omg_merge_tracking_branch_symbol
                fi

                if [[ $has_diverged == true ]]; then
                    prompt+=$(enrich_append true "-${commits_behind} ${omg_has_diverged_symbol} +${commits_ahead}" "${git_status_bg}")
                else
                    if [[ $commits_behind -gt 0 ]]; then
                        prompt+=$(enrich_append true "-${commits_behind} %F{white}${omg_can_fast_forward_symbol}%F{white} --" "${git_status_bg}")
                    fi
                    if [[ $commits_ahead -gt 0 ]]; then
                        prompt+=$(enrich_append true "-- %F{white}${omg_should_push_symbol}%F{white}  +${commits_ahead}" "${git_status_bg}")
                    fi
                    if [[ $commits_ahead == 0 && $commits_behind == 0 ]]; then
                         prompt+=$(enrich_append true " --   -- " "${git_status_bg}")
                    fi
                    
                fi
                prompt+=$(enrich_append true "(${current_branch} ${type_of_upstream} ${upstream//\/$current_branch/})" "${git_status_bg}")
            fi
        fi
        prompt+=$(enrich_append ${is_on_a_tag} "${omg_is_on_a_tag_symbol} ${tag_at_current_commit}" "${git_status_bg}")
        prompt+="%k%F{${git_status_color}}%k%f
${omg_second_line}"
    else
        prompt="$(default_build_prompt)"
    fi
 
    echo "${prompt}"
}

# More symbols to choose from:
# ☀ ✹ ☔ ☄ ♆ ♀ ♁ ♐ ♇ ♈ ♉ ♚ ♛ ♜ ♝ ♞ ♟ ♠ ♣ ⚢ ⚲ ⚳ ⚴ ⚥ ⚤ ⚦ ⚒ ⚑ ⚐ ♺ ♻ ♼ ☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷
# ✡ ✔ ✖ ✚ ✱ ✤ ✦ ❤ ➜ ➟ ➼ ✂ ✎ ✐ ⨀ ⨁ ⨂ ⨍ ⨎ ⨏ ⨷ ⩚ ⩛ ⩡ ⩱ ⩲ ⩵  ⩶ ⨠ 
# ⬅ ⬆ ⬇ ⬈ ⬉ ⬊ ⬋ ⬒ ⬓ ⬔ ⬕ ⬖ ⬗ ⬘ ⬙ ⬟  ⬤ 〒 ǀ ǁ ǂ ĭ Ť Ŧ ☆ ⭤⛃ ☁ ☂ ✭ ⚡ ➜ 𝝙
#              ↵         ╭─ ╰─  😈 
