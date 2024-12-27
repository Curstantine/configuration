function cdcd
    if test (count $argv) -ne 2
        echo "Usage: cdcd BASE_DIRECTORY PROJECT_NAME"
        return 1
    end

    set -l base_dir $argv[1]
    set -l project_name $argv[2]
    set -l rel_path $base_dir/$project_name
    set -l target_path ~/Code/$rel_path

    if test -d $target_path
        cd $target_path
        return 0
    end

    read -l -P "Directory '$rel_path' not found under '~/Code/'. Do you want to clone it from Git? (y/N) " response
    
    if not string match -qi "y" $response
        echo "Operation canceled. Directory not cloned from Git."
        return 1
    end

    set -l base_dir_path (dirname $target_path)
    if not test -d $base_dir_path
        mkdir -p $base_dir_path
    end

    read -l -P "Enter the Git URL: " git_url
    git clone $git_url $target_path
    and cd $target_path
end
