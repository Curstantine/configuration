function cdcd -a base_directory project_name
	if test (count $argv) -ne 2
		echo "Usage: set_code_location <base_directory> <project_name>"
		return 1
	end

	set -l rel_path (string join "/" $base_directory $project_name)
	set -l target_path (string join "/" $HOME "Code" $rel_path)

	
	if test -d $target_path
		cd $target_path
		return
	end

	read -P "Directory '$rel_path' not found under '~/Code/'. Do you want to clone it from Git? (Y/N): " response
	if not string match -qi "y*" $response
		echo "Operation canceled. Directory not cloned from Git."
		return
	end

	set -l base_dir_path (path dirname $target_path)
	if not test -d $base_dir_path
		mkdir -p $base_dir_path
	end

	cd $base_dir_path

	read -P "Enter the Git URL/SSH: " git_input
	if string match -q "@github:*" $git_input
		set git_input (string replace "@github:" "git@github.com:" $git_input)
	end
	
	git clone $git_url $project_name
	cd $target_pathi
end

complete -c cdcd -f
complete -c cdcd -n "__fish_is_first_token" -a "(ls -1 ~/Code/ 2>/dev/null | grep -E '^[^.]*\$')"
complete -c cdcd -n "test (count (commandline -opc)) -eq 2" -a "(ls -1 ~/Code/(commandline -opc)[2]/ 2>/dev/null | grep -E '^[^.]*\$')"

