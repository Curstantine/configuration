function scs --wraps='systemctl suspend' --description 'alias scs systemctl suspend'
  systemctl suspend $argv
        
end
