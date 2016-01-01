if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?* ; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

#feh --bg-scale /home/rijo/images/wallpapers/gentoo_black/gentoo_black.png

#wicd-client --tray 1> /dev/null &
#(wait_for_network; GTK2_RC_FILES=$STANDARD_GTK_THEME pidgin 1> /dev/null) &
#xterm -geometry 120x50+50+50 -e 'htop' &

#exec startfluxbox
#exec /usr/bin/glass -w 9
exec awesome
