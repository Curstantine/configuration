function scp --wraps='systemctl poweroff' --wraps='systemctl reboot' --description 'alias scp systemctl poweroff'
  systemctl poweroff $argv
        
end
