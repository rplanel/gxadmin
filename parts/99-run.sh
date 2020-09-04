wrap_time() {
	local TIMEFORMAT="Time to execute $1: %R seconds"
	time "$@"
}

search() { # <term>: Search for a specific command
	if (( $# > 0 )); then
		locate_cmds | correct_cmd | grep $1 | colour_word $1 orange
	else
		locate_cmds | correct_cmd
	fi
}

if (( $# == 0 )); then
	usage
fi

mode="$1"; shift
wrapper=
if [[ "$mode" == time* ]]; then
	wrapper=wrap_time
	mode=${mode:4}
fi

case "$mode" in
	#*query ) $wrapper query "$mode" "$@" ;;
	*query ) $wrapper look_for "query"  "$mode" "$@" ;;
	*server) $wrapper look_for "server" "$mode" "$@" ;;
	*mutate) $wrapper look_for "mutate" "$mode" "$@" ;;
	config ) $wrapper look_for "$mode" "none"  "$@" ;;
	cluster) $wrapper look_for "$mode" "none"  "$@" ;;
	filter ) $wrapper look_for "$mode" "none"  "$@" ;;
	galaxy ) $wrapper look_for "$mode" "none"  "$@" ;;
	meta   ) $wrapper look_for "$mode" "none"  "$@" ;;
	report ) $wrapper look_for "$mode" "none"  "$@" ;;
	uwsgi  ) $wrapper look_for "$mode" "none"  "$@" ;;
	local  ) $wrapper look_for "$mode" "none"  "$@" ;;
	s      ) search "$@" ;;
	find   ) search "$@" ;;
	search ) search "$@" ;;

	# version commands
	version   ) version ;;
	-v        ) version ;;
	--version ) version ;;
	# help
	help      ) usage;;
	-h        ) usage;;
	--help    ) usage;;
	# anything else
	*         ) usage;;
esac
