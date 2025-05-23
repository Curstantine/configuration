function clear_stale_branches
	git fetch --prune
	for branch in (git branch -vv | grep 'gone]' | awk '{print $1}')
		git branch -D $branch
	end
end
