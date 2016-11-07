# Source file specific per computer
if [ -s ~/.bash_profile.local ]; then
    source ~/.bash_profile.local
fi

# Source user's .bashrc and is recommended by the bash info pages
if [ -s ~/.bashrc ]; then
    source ~/.bashrc
fi
