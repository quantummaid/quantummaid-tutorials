function log() {
    if [ "$#" -gt 0 ]; then
        local msg="$1" && shift
        printf "\n  - $msg\n" "$@"
    else
        printf "\n    ---\n" "$@"
        while read line; do printf "    %s\n" "${line}"; done;
        printf "\n    ---\n" "$@"
    fi
}
