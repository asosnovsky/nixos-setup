

function restart-wifi {
    echo "Removing mod for wifi module..."
    sudo rmmod mt7921e
    echo "Reloading mod for wifi module..."
    sudo modprobe mt7921e
}


function start-windows() {
    quickemu --vm /mnt/Data/vms/windows-11.conf --display spice --viewer remote-viewer
}

function start-windows-app() {
    google-chrome-stable --app=https://windows365.microsoft.com/webclient --new-window
}

# function clean-file() {
#     ${@} | grep -v '^\s*#'  | grep -v '^$'
# }

function clean-k8s-install() {
    sudo rm -rf /var/lib/kubernetes/ /var/lib/etcd/ /var/lib/cfssl/ /var/lib/kubelet/ /etc/kube-flannel/ /etc/kubernetes/
}

function fix-nix-store() {
    sudo nix-store --verify --check-contents --repair
}

function start-sibli-vpn() {
    export BW_SESSION="$(bw unlock --raw)"
    bw unlock --check
    if [ "$?" -eq 1 ]; then
        echo "Failed bw auth"
        return 1
    fi
    pritunl-client start ee73mkzn4i5ymbax -p  $(bw get item "Pritunl (Sibli)" | jq -r '.fields[0].value')$(bw get totp "Pritunl (Sibli)") && watch -n1 "pritunl-client list"
}