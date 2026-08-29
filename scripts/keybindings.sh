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
