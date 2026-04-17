#!/bin/zsh
# Shared tmux session picker (zsh)
case $- in *i*) ;; *) return;; esac

_load_sessions() {
    sessions=()
    local line
    while IFS= read -r line; do
        sessions+=("$line")
    done < <(tmux list-sessions -F "#S" 2>/dev/null)
    sessions+=("[+ new session]")
    total=${#sessions[@]}
}

_tmux_pick() {
    local -a sessions
    _load_sessions
    local sel=1
    local total=${#sessions[@]}

    _draw() {
        clear >/dev/tty
        printf "\e[1;35mWelcome to Safehouse\e[0m\n\n" >/dev/tty
        printf "Select tmux session  (↑↓ move · Enter select · d delete)\n\n" >/dev/tty
        local i
        for (( i=1; i<=total; i++ )); do
            if (( i == sel )); then
                printf "    \e[7m%-30s\e[0m\n" "${sessions[$i]}" >/dev/tty
            else
                printf "    %-30s\n" "${sessions[$i]}" >/dev/tty
            fi
        done
    }

    _refresh_sessions() {
        local old_sel="${sessions[$sel]:-}"
        _load_sessions
        total=${#sessions[@]}
        if [[ -n "$old_sel" ]]; then
            local i
            for (( i=1; i<=total; i++ )); do
                [[ "${sessions[$i]}" == "$old_sel" ]] && sel=$i && break
            done
        fi
        (( sel > total )) && sel=$total
    }

    tput civis >/dev/tty
    _draw

    local key
    while true; do
        key=""
        if read -rsk1 -t 2 key </dev/tty 2>/dev/null; then
            if [[ "$key" == $'\x1b' ]]; then
                local seq=""
                read -rsk2 -t 0.1 seq </dev/tty 2>/dev/null
                case "$seq" in
                    '[A') (( sel > 1 )) && (( sel-- )) ;;
                    '[B') (( sel < total )) && (( sel++ )) ;;
                esac
            elif [[ "$key" == $'\n' || "$key" == $'\r' || -z "$key" ]]; then
                tput cnorm >/dev/tty
                echo "${sessions[$sel]}"
                return
            elif [[ "$key" == 'd' ]]; then
                local name="${sessions[$sel]}"
                if [[ "$name" != "[+ new session]" ]]; then
                    tput cnorm >/dev/tty
                    clear >/dev/tty
                    local confirm=""
                    printf "Delete '%s'? [y/N]: " "$name" >/dev/tty
                    read -r confirm </dev/tty
                    if [[ "$confirm" == [yY] ]]; then
                        tmux kill-session -t "$name" 2>/dev/null
                    fi
                    _load_sessions
                    total=${#sessions[@]}
                    (( sel > total )) && sel=$total
                    tput civis >/dev/tty
                fi
            fi
        else
            # read timed out — refresh list
            _refresh_sessions
        fi
        _draw
    done
}

alias ts='tmux-select'
tmux-select() {
    local result
    result=$(_tmux_pick)
    tput cnorm >/dev/tty
    clear

    if [[ "$result" == "[+ new session]" ]]; then
        local name=""
        printf "Session name [main]: " >/dev/tty
        read -r name
        if [[ -n "$TMUX" ]]; then
            tmux new-session -d -s "${name:-main}" && tmux switch-client -t "${name:-main}"
        else
            tmux new-session -s "${name:-main}"
        fi
    elif [[ -n "$result" ]]; then
        if [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$result"
        else
            tmux attach -t "$result" 2>/dev/null || tmux new-session -s "$result"
        fi
    fi
}

# Auto-run picker when opening a shell outside tmux
if command -v tmux &>/dev/null && [[ -z "$TMUX" ]] && [[ -t 0 ]]; then
    local result
    result=$(_tmux_pick)
    tput cnorm >/dev/tty
    clear

    if [[ "$result" == "[+ new session]" ]]; then
        local name=""
        printf "Session name [main]: " >/dev/tty
        read -r name
        tmux new-session -s "${name:-main}"
    elif [[ -n "$result" ]]; then
        tmux attach -t "$result" 2>/dev/null || tmux new-session -s "$result"
    fi
fi
