

function restart-wifi {
    echo "Removing mod for wifi module..."
    sudo rmmod mt7921e 
    echo "Reloading mod for wifi module..."
    sudo modprobe mt7921e
}