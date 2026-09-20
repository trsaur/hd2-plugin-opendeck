#!/bin/bash

clear

# Detect current settings
if grep -q 'keydown w' ./scripts/keybindings.sh 2>/dev/null; then
    CURRENT_MOVEMENT="WASD"
else
    CURRENT_MOVEMENT="Arrow keys"
fi

if grep -q 'keydown Control_R' ./scripts/keybindings.sh 2>/dev/null; then
    CURRENT_CTRL="Right Ctrl"
else
    CURRENT_CTRL="Left Ctrl"
fi

printf "Current settings: %s movement, %s call stratagem key\n" "$CURRENT_MOVEMENT" "$CURRENT_CTRL"
printf "\n"

# --- Question 1: movement keys ---
printf "Choose your preferable stratagem movement input:\n"
printf "1 - WASD (Default)\n"
printf "2 - Arrow keys\n"
printf "q - Quit without changes\n"
printf "\n"

MOVEMENT=""
while true; do
    read -p "Enter 1, 2 or q: " choice
    case "${choice}" in
        1) MOVEMENT="wasd"; break ;;
        2) MOVEMENT="arrow"; break ;;
        q) echo "Quit without changes..."; sleep 1; exit 0 ;;
        *) echo "Incorrect input"; printf "\n" ;;
    esac
done

# --- Question 2: ctrl key ---
printf "\n"
printf "Choose your preferable stratagem call key:\n"
printf "1 - Left Ctrl (Default)\n"
printf "2 - Right Ctrl\n"
printf "q - Quit without changes\n"
printf "\n"

CTRL_KEY=""
while true; do
    read -p "Enter 1, 2 or q: " choice
    case "${choice}" in
        1) CTRL_KEY="Control_L"; break ;;
        2) CTRL_KEY="Control_R"; break ;;
        q) echo "Quit without changes..."; sleep 1; exit 0 ;;
        *) echo "Incorrect input"; printf "\n" ;;
    esac
done

# --- Map movement selection to actual keysyms ---
if [[ "$MOVEMENT" == "wasd" ]]; then
    UP_KEY="w"; DOWN_KEY="s"; LEFT_KEY="a"; RIGHT_KEY="d"
else
    UP_KEY="Up"; DOWN_KEY="Down"; LEFT_KEY="Left"; RIGHT_KEY="Right"
fi

# --- Write keybindings.sh ---
cat > ./scripts/keybindings.sh <<EOF
#!/bin/bash

SL () {
	/usr/bin/sleep 0.05
}

UP () {
	/usr/bin/xdotool keydown ${UP_KEY}
	SL
	/usr/bin/xdotool keyup ${UP_KEY}
	SL
}

DOWN () {
	/usr/bin/xdotool keydown ${DOWN_KEY}
	SL
	/usr/bin/xdotool keyup ${DOWN_KEY}
	SL
}

LEFT () {
	/usr/bin/xdotool keydown ${LEFT_KEY}
	SL
	/usr/bin/xdotool keyup ${LEFT_KEY}
	SL
}

RIGHT () {
	/usr/bin/xdotool keydown ${RIGHT_KEY}
	SL
	/usr/bin/xdotool keyup ${RIGHT_KEY}
	SL
}

M1 () {
	/usr/bin/xdotool mousedown 1
	SL
	/usr/bin/xdotool mouseup 1
}

CTRL () {
	/usr/bin/xdotool keydown ${CTRL_KEY}
	SL
	/usr/bin/xdotool keyup ${CTRL_KEY}
	SL
}
EOF

echo "keybindings.sh updated: ${MOVEMENT} movement, ${CTRL_KEY} as call stratagem key"
