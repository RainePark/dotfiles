#!/bin/bash

# Increases volume and brightness
# Adapted from gitlab.com/Nmoleo/i3-volume-brightness-indicator

bar_color="#f8f8f2"
# Alternate bar colour with default rofi colours 
# bar_color="#eee8d5"
volume_step=10
brightness_step=10
max_volume=100

# Uses regex to get volume from pactl
function get_volume {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]{1,3}(?=%)' | head -1
}

# Get the active output form pactl
function get_active {
	pactl list sinks | grep -A 20 $(pactl get-default-sink) | sed -n 's/.*Description: \(.*\)/\1/p'
}

# Uses regex to get mute status from pactl
function get_mute {
    pactl get-sink-mute @DEFAULT_SINK@ | grep -Po '(?<=Mute: )(yes|no)'
}

# Uses regex to get brightness from xbacklight
function get_brightness {
    brightnessctl -P get | head -n 1
}

# Returns a mute icon, a volume-low icon, or a volume-high icon, depending on the volume
function get_volume_icon {
    volume=$(get_volume)
    mute=$(get_mute)
    if [ "$volume" -eq 0 ] || [ "$mute" == "yes" ] ; then
        volume_icon=""
    elif [ "$volume" -lt 50 ]; then
        volume_icon=""
    else
        volume_icon=""
    fi
}

# Always returns the same icon - I couldn't get the brightness-low icon to work with fontawesome
function get_brightness_icon {
    brightness_icon=""
}

# Displays a volume notification using dunstify
function show_volume_notif {
    volume=$(get_mute)
    device=$(get_active)
    get_volume_icon
    dunstify -i audio-volume-muted-blocking -t 1000 -r 2593 -u normal "$volume_icon  $volume% ($device)" -h int:value:$volume -h string:hlcolor:$bar_color
}

# Displays a brightness notification using dunstify
function show_brightness_notif {
    brightness=$(get_brightness)
    get_brightness_icon
    dunstify -t 1000 -r 2593 -u normal "$brightness_icon $brightness%" -h int:value:$brightness -h string:hlcolor:$bar_color
}

# Main function - Takes user input, "volume_up", "volume_down", "brightness_up", or "brightness_down"
case $1 in
    volume_up)
    # Unmutes and increases volume, then displays the notification
    pactl set-sink-mute @DEFAULT_SINK@ 0
    volume=$(get_volume)
    if [ $(( "$volume" + "$volume_step" )) -gt $max_volume ]; then
        pactl set-sink-volume @DEFAULT_SINK@ $max_volume%
    else
        pactl set-sink-volume @DEFAULT_SINK@ +$volume_step%
    fi
    show_volume_notif
    ;;

    volume_down)
    # Raises volume and displays the notification
    pactl set-sink-volume @DEFAULT_SINK@ -$volume_step%
    show_volume_notif
    ;;

    volume_mute)
    # Toggles mute and displays the notification
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    show_volume_notif
    ;;

    brightness_up)
    # Increases brightness and displays the notification
    brightness=$(get_brightness)
    brightnessctl set "$((brightness+brightness_step))%"
    show_brightness_notif
    ;;

    brightness_down)
    # Decreases brightness and displays the notification
    brightness=$(get_brightness)
    if [ $((brightness-brightness_step)) -lt 0 ]; then
	brightnessctl set "0%"
    else
	brightnessctl set "$((brightness-brightness_step))%"
    fi
    show_brightness_notif
    ;;
esac

