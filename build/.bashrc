# Interactive tmux session picker
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -t 0 ]; then
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
