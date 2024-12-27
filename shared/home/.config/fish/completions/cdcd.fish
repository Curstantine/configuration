# Completion for the first argument (base directory)
complete -c cdcd -n "test (count (commandline -opc)) -eq 1" -a "(
    find ~/Code -maxdepth 0 -type d
)"

# Completion for the second argument (project name)
# complete -c cdcd -n "test (count (commandline -opc)) -eq 2" -a "(
#     set -l base_dir (commandline -opc)[2];
#     cd ~/Code/$base_dir 2>/dev/null;
#     or exit 0;
#     find * -maxdepth 0 -type d 2>/dev/null;
#     ls -d */ 2>/dev/null | string replace -r '/\$' ''
# )"

# Add description for the command itself
complete -c cdcd -n "test (count (commandline -opc)) -eq 0" \
    -d "Navigate to or clone a code project"
