# Interactive tmux session picker
_tmux_pick() {
    local sessions=()
    mapfile -t sessions < <(tmux list-sessions -F "#S" 2>/dev/null)
    sessions+=("[+ new session]")
    local total=${#sessions[@]}
    local sel=0

    _draw() {
        clear >/dev/tty
        printf "\e[1;35mWelcome to Safehouse\e[0m\n\n" >/dev/tty
        printf "Select tmux session  (↑↓ move · Enter select · d delete)\n\n" >/dev/tty
        for i in "${!sessions[@]}"; do
            if [ "$i" -eq "$sel" ]; then
                printf "    \e[7m%-30s\e[0m\n" "${sessions[$i]}" >/dev/tty
            else
                printf "    %-30s\n" "${sessions[$i]}" >/dev/tty
            fi
        done
    }

    tput civis >/dev/tty
    _draw

    while true; do
        IFS= read -rsn1 key </dev/tty
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 seq </dev/tty
            case $seq in
                '[A') ((sel > 0)) && ((sel--)) ;;
                '[B') ((sel < total - 1)) && ((sel++)) ;;
            esac
        elif [[ $key == '' ]]; then
            tput cnorm >/dev/tty
            echo "${sessions[$sel]}"
            return
        elif [[ $key == 'd' ]]; then
            local name="${sessions[$sel]}"
            if [[ $name != "[+ new session]" ]]; then
                tput cnorm >/dev/tty
                clear >/dev/tty
                read -p "Delete '$name'? [y/N]: " confirm </dev/tty >/dev/tty
                if [[ $confirm == [yY] ]]; then
                    tmux kill-session -t "$name" 2>/dev/null
                fi
                sessions=()
                mapfile -t sessions < <(tmux list-sessions -F "#S" 2>/dev/null)
                sessions+=("[+ new session]")
                total=${#sessions[@]}
                ((sel >= total)) && sel=$((total - 1))
                tput civis >/dev/tty
            fi
        fi
        _draw
    done
}

# Select/switch tmux session (works both inside and outside tmux)
alias ts='tmux-select'
tmux-select() {
    local result
    result=$(_tmux_pick)
    tput cnorm >/dev/tty
    clear

    if [[ $result == "[+ new session]" ]]; then
        read -p "Session name [main]: " name
        if [ -n "$TMUX" ]; then
            tmux new-session -d -s "${name:-main}" && tmux switch-client -t "${name:-main}"
        else
            tmux new-session -s "${name:-main}"
        fi
    elif [ -n "$result" ]; then
        if [ -n "$TMUX" ]; then
            tmux switch-client -t "$result"
        else
            tmux attach -t "$result" 2>/dev/null || tmux new-session -s "$result"
        fi
    fi
}

# Auto-run picker when opening a shell outside tmux
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -t 0 ]; then
    result=$(_tmux_pick)
    tput cnorm >/dev/tty
    clear

    if [[ $result == "[+ new session]" ]]; then
        read -p "Session name [main]: " name
        tmux new-session -s "${name:-main}"
    elif [ -n "$result" ]; then
        tmux attach -t "$result" 2>/dev/null || tmux new-session -s "$result"
    fi
fi
