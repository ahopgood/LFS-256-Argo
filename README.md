# LFS-256-Argo

A place to work on LFS-256 labs

## Lab 1 - Installing ArgoCD
* Create a cluster `make start`
* Add namespace
  * `kubectl create namespace argocd`
* Deploy ArgoCD using the quickstart manifest
```
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
````
### Login via UI
* Setup port forwarding for the service
```
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
```
* Extract the automatically generated password.
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
* UI can be found on [http://localhost:8081](http://localhost:8081)

### Login via CLI
* Login using the port-forward and the password from above.
```
argocd login localhost:8081 --username admin --password <PASSWORD>
```

## Lab 2 - Managing Applications with Argo CD
