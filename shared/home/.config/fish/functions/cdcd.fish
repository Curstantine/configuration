function cdcd -d "Set code location or clone from Git if not exists"
    # Arguments with descriptions
    argparse 'b/base-directory=' 'p/project-name=' -- $argv
    or return

    # Set variables from arguments or use defaults
    set -l base_dir (if set -q _flag_base_directory; echo $_flag_base_directory; else; echo ""; end)
    set -l proj_name (if set -q _flag_project_name; echo $_flag_project_name; else; echo ""; end)

    # Construct paths
    set -l rel_path (string join "/" $base_dir $proj_name)
    set -l target_path ~/Code/$rel_path

    # Check if directory exists
    if test -d $target_path
        cd $target_path
        return 0
    end

    # Ask user if they want to clone
    read -P "Directory '$rel_path' not found under '~/Code/'. Clone from Git? (Y/N) " response
    if not string match -qi "y" $response
        echo "Operation canceled. Directory not cloned from Git."
        return 1
    end

    # Create base directory if it doesn't exist
    set -l base_dir_path (dirname $target_path)
    if not test -d $base_dir_path
        mkdir -p $base_dir_path
    end

    # Get Git URL and clone
    read -P "Enter the Git URL: " git_url
    git clone $git_url $target_path
    cd $target_path
end

# Tab completion
complete -c cdcd -l base-directory -s b -d "Base directory path"
complete -c cdcd -l project-name -s p -d "Project name"
