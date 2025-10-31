function scr --wraps='systemctl reboot' --description 'alias scr systemctl reboot'
  systemctl reboot $argv
        
end
