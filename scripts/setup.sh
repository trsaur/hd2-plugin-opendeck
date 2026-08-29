#!/bin/bash

clear
grep 'keydown w' ./keybindings.sh -q && printf "WASD strategem input is active\n" || printf "Arrow keys strategem input is active\n"
printf "\n"
printf "Choose your preferable strategem input:\n"
printf "1 - WASD (Default)\n"
printf "2 - Arrow keys\n"
printf "q - Quit without changes\n"
printf "\n"

WASD () {
	cat > ./keybindings.sh <<EOF
#!/bin/bash

SL () {
	/usr/bin/sleep 0.05
}

UP () {
	/usr/bin/xdotool keydown w
	SL
	/usr/bin/xdotool keyup w
	SL
}

DOWN () {
	/usr/bin/xdotool keydown s
	SL
	/usr/bin/xdotool keyup s
	SL
}

LEFT () {
	/usr/bin/xdotool keydown a
	SL
	/usr/bin/xdotool keyup a
	SL
}

RIGHT () {
	/usr/bin/xdotool keydown d
	SL
	/usr/bin/xdotool keyup d
	SL
}

M1 () {
	/usr/bin/xdotool mousedown 1
	SL
	/usr/bin/xdotool mouseup 1
}

CTRL () {
	/usr/bin/xdotool keydown ctrl
	SL
	/usr/bin/xdotool keyup ctrl
	SL
}
EOF
}

ARROWKEYS () {
	cat > ./keybindings.sh <<EOF
#!/bin/bash

SL () {
	/usr/bin/sleep 0.05
}

UP () {
	/usr/bin/xdotool keydown Up
	SL
	/usr/bin/xdotool keyup Up
	SL
}

DOWN () {
	/usr/bin/xdotool keydown Down
	SL
	/usr/bin/xdotool keyup Down
	SL
}

LEFT () {
	/usr/bin/xdotool keydown Left
	SL
	/usr/bin/xdotool keyup Left
	SL
}

RIGHT () {
	/usr/bin/xdotool keydown Right
	SL
	/usr/bin/xdotool keyup Right
	SL
}

M1 () {
	/usr/bin/xdotool mousedown 1
	SL
	/usr/bin/xdotool mouseup 1
}

CTRL () {
	/usr/bin/xdotool keydown ctrl
	SL
	/usr/bin/xdotool keyup ctrl
	SL
}
EOF
}

while true; do
	read -p "Enter 1,2 or 3 (q - exit):" strategem_input
	case "${strategem_input}" in

		1)
			echo "1 - WASD selected"
			sleep 1
			WASD
			exit 0
			;;
		2)
			echo "2 - Arrow Keys selected"
			sleep 1
			ARROWKEYS
			exit 0
			;;
		q)
			echo "Quit without changes..."
			sleep 1
			exit 0
			;;
		*)
			echo "Incorrect input"
			printf "\n"
			;;
	esac
done
