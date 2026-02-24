# Rollouts
## Running the rollout
* Apply the rollout
```
kubectl apply -f rollouts/rollout-example.yaml
```

### Inspecting the rollout
* View the rollout status 
```
kubectl get rollout
```
* Returns
```
NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
rollout-bluegreen   2                                            3s
```

* Inspect why the rollout isn't ready yet
```
kubectl argo rollouts get ro rollout-bluegreen
```
* Returns
```
Name:            rollout-bluegreen
Namespace:       default
Status:          ✖ Degraded
Message:         InvalidSpec: The Rollout "rollout-bluegreen" is invalid: spec.strategy.blueGreen.activeService: Invalid value: "rollout-bluegreen-active": service "rollout-bluegreen-active" not found
Strategy:        BlueGreen
Replicas:
  Desired:       2
  Current:       0
  Updated:       0
  Ready:         0
  Available:     0

NAME                 KIND     STATUS      AGE  INFO
⟳ rollout-bluegreen  Rollout  ✖ Degraded  10s  
```
* This is due to the active and preview services being missing
```
kubectl apply -f rollouts/preview-service.yaml,rollouts/active-service.yaml
``` 
* Now the status should change:
```
Name:            rollout-bluegreen
Namespace:       default
Status:          ✔ Healthy
Strategy:        BlueGreen
Images:          argoproj/rollouts-demo:blue (stable, active)
Replicas:
  Desired:       2
  Current:       2
  Updated:       2
  Ready:         2
  Available:     2

NAME                                           KIND        STATUS     AGE  INFO
⟳ rollout-bluegreen                            Rollout     ✔ Healthy  42s  
└──# revision:1                                                            
   └──⧉ rollout-bluegreen-5ffd47b8d4           ReplicaSet  ✔ Healthy  15s  stable,active
      ├──□ rollout-bluegreen-5ffd47b8d4-dc9m4  Pod         ✔ Running  5s   ready:1/1
      └──□ rollout-bluegreen-5ffd47b8d4-mlmcn  Pod         ✔ Running  5s   ready:1/1
```
### Performing an upgrade
* As part of our blue/green rollout we want to promote the `green` image:
```
kubectl apply -f rollouts/rollout-green.yaml
```
The rollout status will move from `Healthy` to `Paused`: 
```
kubectl argo rollouts get ro rollout-bluegreen
Name:            rollout-bluegreen
Namespace:       default
Status:          ॥ Paused
Message:         BlueGreenPause
Strategy:        BlueGreen
Images:          argoproj/rollouts-demo:blue (stable, active)
argoproj/rollouts-demo:green (preview)
Replicas:
Desired:       2
Current:       4
Updated:       2
Ready:         2
Available:     2

NAME                                           KIND        STATUS     AGE    INFO
⟳ rollout-bluegreen                            Rollout     ॥ Paused   6m42s  
├──# revision:2                                                              
│  └──⧉ rollout-bluegreen-75695867f            ReplicaSet  ✔ Healthy  49s    preview
│     ├──□ rollout-bluegreen-75695867f-trxxt   Pod         ✔ Running  49s    ready:1/1
│     └──□ rollout-bluegreen-75695867f-zndw4   Pod         ✔ Running  49s    ready:1/1
└──# revision:1                                                              
└──⧉ rollout-bluegreen-5ffd47b8d4           ReplicaSet  ✔ Healthy  6m15s  stable,active
├──□ rollout-bluegreen-5ffd47b8d4-dc9m4  Pod         ✔ Running  6m5s   ready:1/1
└──□ rollout-bluegreen-5ffd47b8d4-mlmcn  Pod         ✔ Running  6m5s   ready:1/1     ✔ Running            5m17s  ready:1/1
```
* View the replica sets 
```
kubectl get replicase
```
* Returns
```
NAME                           DESIRED   CURRENT   READY   AGE
rollout-bluegreen-5ffd47b8d4   2         2         2       7m58s
rollout-bluegreen-75695867f    2         2         2       2m32s
```
* We have a second replica set to allow us to have two different versions running at once (in this case two image tags)
* Now we're going to promote the deployment
```
kubectl argo rollouts promote rollout-bluegreen
```
* Returns
```
rollout 'rollout-bluegreen' promoted
```
* We now see that the rollout is no longer in the `Paused` state:
```
Name:            rollout-bluegreen
Namespace:       default
Status:          ✔ Healthy
Strategy:        BlueGreen
Images:          argoproj/rollouts-demo:blue
                 argoproj/rollouts-demo:green (stable, active)
Replicas:
  Desired:       2
  Current:       4
  Updated:       2
  Ready:         2
  Available:     2

NAME                                           KIND        STATUS     AGE    INFO
⟳ rollout-bluegreen                            Rollout     ✔ Healthy  12m    
├──# revision:2                                                              
│  └──⧉ rollout-bluegreen-75695867f            ReplicaSet  ✔ Healthy  6m53s  stable,active
│     ├──□ rollout-bluegreen-75695867f-trxxt   Pod         ✔ Running  6m53s  ready:1/1
│     └──□ rollout-bluegreen-75695867f-zndw4   Pod         ✔ Running  6m53s  ready:1/1
└──# revision:1                                                              
   └──⧉ rollout-bluegreen-5ffd47b8d4           ReplicaSet  ✔ Healthy  12m    delay:11s
      ├──□ rollout-bluegreen-5ffd47b8d4-dc9m4  Pod         ✔ Running  12m    ready:1/1
      └──□ rollout-bluegreen-5ffd47b8d4-mlmcn  Pod         ✔ Running  12m    ready:1/1
```
* The images have switched places with `green` now marked with `(stable, active)`
* The first revision (`blue`) will display `delay` and a countdown before being scaled down.
* `kubectl describe svc rollout-bluegreen-active` will show this `blue` service scaled down:
```
Name:                     rollout-bluegreen-active
Namespace:                default
Labels:                   app=rollout-bluegreen-active
Annotations:              argo-rollouts.argoproj.io/managed-by-rollouts: rollout-bluegreen
Selector:                 app=rollout-bluegreen,rollouts-pod-template-hash=75695867f
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.103.104
IPs:                      10.96.103.104
Port:                     80  80/TCP
TargetPort:               80/TCP
Endpoints:                10.244.0.17:80,10.244.0.18:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```
### Rollback
```
kubectl argo rollouts undo rollout-bluegreen
```
* We'll see the old `blue` deployment being rolled out and `green` being paused and then rolled back:
```
Name:            rollout-bluegreen
Namespace:       default
Status:          ॥ Paused
Message:         BlueGreenPause
Strategy:        BlueGreen
Images:          argoproj/rollouts-demo:blue (stable, active)
                 argoproj/rollouts-demo:green (preview)
Replicas:
  Desired:       2
  Current:       4
  Updated:       2
  Ready:         2
  Available:     2

NAME                                           KIND        STATUS     AGE  INFO
⟳ rollout-bluegreen                            Rollout     ॥ Paused   21m  
├──# revision:8                                                            
│  └──⧉ rollout-bluegreen-75695867f            ReplicaSet  ✔ Healthy  15m  preview
│     ├──□ rollout-bluegreen-75695867f-n4lb2   Pod         ✔ Running  18s  ready:1/1
│     └──□ rollout-bluegreen-75695867f-rgb8p   Pod         ✔ Running  18s  ready:1/1
└──# revision:7                                                            
   └──⧉ rollout-bluegreen-5ffd47b8d4           ReplicaSet  ✔ Healthy  20m  stable,active
      ├──□ rollout-bluegreen-5ffd47b8d4-fmwk5  Pod         ✔ Running  92s  ready:1/1
      └──□ rollout-bluegreen-5ffd47b8d4-vp659  Pod         ✔ Running  92s  ready:1/1
```
* Note you'll need to promote  again:
```
kubectl argo rollouts promote rollout-bluegreen
```
### Tidy up
* Delete the rollout 
```
kubectl delete rollout rollout-bluegreen
```
* Delete the services associated with the rollout:
```
kubectl delete svc rollout-bluegreen-active,rollout-bluegreen-preview 
```

## Migrating Deployments to Rollouts
* Create an nginx deployment
```
kubectl create deploy nginx-deployment --image=nginx --replicas=3
```
* The `migrated-rollout.yaml` points to our deployment via 
```
workloadRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
```
* Apply it
```
kubectl apply -f rollouts/migrated-rollout.yaml 
```
* Now we have 6 instances; 3 via k8s Deployment and another 3 via Rollouts: 
```
kubectl get ro,deployment,po  
NAME                                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
rollout.argoproj.io/nginx-rollout   3         3         3            3           49s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   3/3     3            3           4m8s

NAME                                    READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-6cfb98644c-4gtbb   1/1     Running   0          4m8s
pod/nginx-deployment-6cfb98644c-gb9rl   1/1     Running   0          4m8s
pod/nginx-deployment-6cfb98644c-w8bgr   1/1     Running   0          4m8s
pod/nginx-rollout-6d7df6cfcb-4vbv4      1/1     Running   0          49s
pod/nginx-rollout-6d7df6cfcb-scthb      1/1     Running   0          49s
pod/nginx-rollout-6d7df6cfcb-wscjf      1/1     Running   0          49s
```
### Scale down the deployment
```
kubectl scale deployment/nginx-deployment --replicas=0
```
* Scaling down can also be done via the Argo Rollout Controller via the `scaleDown` parameter (with values: `never`, `onsuccess`, `progressively`)
```
  workloadRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
    scaleDown: onsuccess
```
### Tidy Up
* Delete the rollout
```
kubectl delete rollout nginx-rollout
```
* Delete the deployment
```
kubectl delete deployment nginx-deployment
```

## Troubleshooting
> time="2026-02-23T10:54:39Z" level=info msg="pkg/mod/k8s.io/client-go@v0.29.3/tools/cache/reflector.go:229: failed to list argoproj.io/v1alpha1, Resource=analysisruns: the server could not find the requested resource"

The crd for `analysisruns` doesn't exist, try restarting the environment. 