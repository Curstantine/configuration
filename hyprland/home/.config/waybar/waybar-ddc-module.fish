#!/usr/bin/fish

# Initial idea by https://gist.github.com/Ar7eniyan/42567870ad2ce47143ffeb41754b4484

if test (count $argv) -eq 0
    echo "Usage: $0 <bus_number>"
    echo "Example: $0 7"
    exit 1
end

set bus_number $argv[1]
set receive_pipe "/tmp/waybar-ddc-module-rx-bus$bus_number"
set step 5

function ddcutil_fast
    # multiplier should be chosen so that it both works reliably and fast enough
    ddcutil --noverify --bus $bus_number --sleep-multiplier .03 $argv 2>/dev/null
end

function ddcutil_slow
    ddcutil --maxtries 15,15,15 $argv 2>/dev/null
end

# takes ddcutil commandline as arguments
function print_brightness
    set brightness (eval $argv -t getvcp 10)
    if test $status -eq 0
        set brightness (echo $brightness | cut -d ' ' -f 4)
    else
        set brightness -1
    end

	echo '{ "percentage":' $brightness '}'
end

rm -rf $receive_pipe
mkfifo $receive_pipe

print_brightness ddcutil_slow

while true
    read -l command < $receive_pipe
    switch $command
        case "+" "-"
            ddcutil_fast setvcp 10 $command $step
        case "max"
            ddcutil_fast setvcp 10 100
        case "min"
            ddcutil_fast setvcp 10 0
    end

	print_brightness ddcutil_fast
end
