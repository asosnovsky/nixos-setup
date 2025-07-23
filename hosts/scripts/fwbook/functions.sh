function start-windows() {
    quickemu --vm /mnt/Data/vms/windows-11.conf --display spice --viewer remote-viewer
}

function start-windows-app() {
    google-chrome-stable --app=https://windows365.microsoft.com/webclient --new-window
}

function clean-file() {
    grep -v '^\s*#'  | grep -v '^$'
}

function clean-k8s-install() {
    sudo rm -rf /var/lib/kubernetes/ /var/lib/etcd/ /var/lib/cfssl/ /var/lib/kubelet/ /etc/kube-flannel/ /etc/kubernetes/
}

function fix-nix-store() {
    sudo nix-store --verify --check-contents --repair
}
