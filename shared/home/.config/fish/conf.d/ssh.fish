set -Ux SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
set -Ux SSH_ASKPASS /usr/bin/ksshaskpass
set -Ux SSH_ASKPASS_REQUIRE prefer
