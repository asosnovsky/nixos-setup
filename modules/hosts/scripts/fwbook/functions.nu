
def k8s-namespaces [] {
    kubectl get namespaces -o jsonpath='{.items}' | from json | select metadata.name | rename value
}

def k8s-secrets [namespace: string@k8s-namespaces = ""] {
    if not ($namespace | is-empty) {
        kubectl -n $namespace get secrets -o jsonpath='{.items}' | from json | select metadata.name | rename value
    } else {
        kubectl get secrets -o jsonpath='{.items}' | from json | select metadata.name | rename value
    }
}
def decode-secret [name: string@k8s-secrets] {
    kubectl get secret $name -o jsonpath='{.data}' | 
        from json | 
        transpose key value | 
        update value { |r| $r.value | decode base64 | decode}
}