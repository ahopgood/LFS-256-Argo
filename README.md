# LFS-256-Argo

A place to work on LFS-256 labs

* [Lab 1 - Installing ArgoCD](#lab1)
* [Lab 2 - Managing Applications with Argo CD](#lab2)
* [Lab 3 - Argo CD Security and RBAC](#lab3)

<a href="lab1"></a>
## Lab 1 - Installing ArgoCD
* Create a cluster `make start`
* `tilt up` will perform the following steps:
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

<a href="lab2"></a>
## Lab 2 - Managing Applications with Argo CD
* Fork the repo [LFS256-code](https://github.com/lftraining/LFS256-code)
* Update the `targetPort` in the `service.yaml` manifest to `80` and commit
* In the UI select `New App`
  * Add a name `example-app`
  * As project name choose `default`
  * Under Sync Options tick `Auto-Create Namespace`
  * Under Source paste in the repo of your fork
  * Under Path choose `argocd/example-app` which reflects the path in the repo to the ArgoCD application manifests
  * In destination we define the Cluster-URL as `https://kubernetes.default.svc` 
  * Define a namespace of your choice such as `default`
  * Click `Create`
* Initially the app will be in a `OutOfSync` state. 
* Click `Sync` to sync the app as we've left it as a Manual Sync in our setup

### Access the app
* Port forward the app:
```
kubectl port-forward svc/argocd-example-app-service 9090:80 --address 0.0.0.0
```
* Open a browser and navigate to `https://localhost:9090`
* `curl localhost:9090` also works

### Update the image
* Navigate to `deployment.yaml`
* Update the `image:` to `image: liquidreply/argocd-example-app:2`
* Commit and push the changes 
* Press `Refresh` in the UI and ArgoCD will detect the drift between the current state and the desired state.
* You can change the app to `Auto-Sync` later to automatically pick up changes

### Rollback
* In the UI navigate to the app page
* Select `History and Rollback`
* Find the revision you want, select the kebab menu (three vertical dots)
* Select `Rollback`

### Delete the app
* In the UI navigate to the app page
* Select `Delete`
* You'll be presented with some different strategies
  * Foreground propagation: Delete all child resources before deleting the app
  * Background propagation: Delete app first and leave it to kubernetes to remove the child resources asynchronously afterwards
  * Do not touch the resources at all: leaves the kubernetes resources in place but removes it from ArgoCD's management

<a href="lab3"></a>
## Lab 3 - Argo CD Security and RBAC

### Create a new user