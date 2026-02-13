## Running the workflow
* Give the default service account `admin` permissions so it can run our workflows
```
kubectl create rolebinding default-admin --clusterrole=admin --serviceaccount=argowf:default -n argowf
```
* Apply the workflow template
```
kubectl apply -f workflows/dag-workflow-template.yaml
```
* Start the workflow that uses our template in a Directed Acyclic Graph
```
kubectl create -f workflows/dag-workflow.yaml        
```
## Inspecting the workflow
* List the workflows
```
argo list -n argowf
```
* View details of the workflows
```
argo -n argowf get dag-diamond6g4cv
```
## Tidy up
* Delete the workflow
```
kubectl delete workflow -n argowf dag-diamond6g4cv
```
* Delete the workflow template
```
kubectl delete workflowtemplates.argoproj.io echo-template -n argowf
```
* Delete the rolebinding
```
kubectl delete rolebinding default-admin -n argowf   
```