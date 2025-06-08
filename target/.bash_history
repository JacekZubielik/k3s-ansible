helm template . --name-template argocd --namespace argocd --kube-version 1.31 --values <path to cached source>/clusters/dev/cluster-defaults/cluster-setup.yaml --values <path to cached source>/clusters/dev/tools/argocd/values.yaml --include-crds --debug
ls
kubectl get services
kubectl get services -n kube-system
kubectl describe ingress karma -n kube-system
exit
kubectl get service -m kube-system 
kubectl get service 
kubectl -n kube-system get service 
k -n kube-system get ing
kubectl get endpoints -n kube-ingress ingress-nginx-controller-admission-private-primary
k -n kube-logging get ing
k -n oauth2-proxy-kibana get ing
k -n kube-logging edit ing kibana
kubectl replace -f /tmp/kubectl-edit-3165023169.yaml
k -n kube-system get ing
k -n kube-system edit ing karma
kubectl replace -f /tmp/kubectl-edit-2125346366.yaml
k -n kube-system get ing
k -n kube-system edit ing karma
k -n kube-logging get ing
kubectl get svc -n kube-ingress ingress-nginx-controller-admission-private-primary
kubectl get endpoints -n kube-ingress ingress-nginx-controller-admission-private-primary
kubectl get pods -n kube-ingress -l app=ingress-nginx,component=controller
kubectl get endpoints -n kube-ingress ingress-nginx-controller-admission-private-primary
kubectl get svc -n kube-ingress ingress-nginx-controller-admission-private-primary
k -n kube-logging get ing
kubectl get svc -n kube-ingress ingress-nginx-controller-admission-private-primary
kubectl get endpoints -n kube-ingress ingress-nginx-controller-admission-private-primary
k -n kube-system edit ing karma
kubectl replace -f /tmp/kubectl-edit-3117553030.yaml
kubectl get ing karma -n kube-system -o yaml
