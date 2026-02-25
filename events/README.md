## Installation
```
kubectl create namespace argo-events
kubectl apply -f
https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
```
* Also requires [4. Argo Workflows](https://bookstack.alexanderhopgood.com/books/lfs-256-devops-and-workflow-management-with-argo/page/4-argo-workflows) to be installed

### Validating web hook
* The validating webhook is used to check that incoming requests to the kubernets API are valid:
```
kubectl apply -f
https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install-validating-webhook.yaml
```

## Setting up the event bus
* Sets up a native event bus in the `argo-events` namespace
```
kubectl -n argo-events apply -f
https://raw.githubusercontent.com/argoproj/argo-events/stable/examples
/eventbus/native.yaml
```

## Setting up the events source
```
kubectl -n argo-events apply -f
https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/event-sources/webhook.yaml
```

## Sensor RBAC policy
* Allows for communication with the K8S API
```
kubectl apply -n argo-events -f
https://raw.githubusercontent.com/argoproj/argo-events/master/examples/rbac/sensor-rbac.yaml
```

## RBAC for workflows
```
kubectl apply -n argo-events -f
https://raw.githubusercontent.com/argoproj/argo-events/master/examples/rbac/workflow-rbac.yaml
```
### Set up the Sensor
```
kubectl apply -n argo-events -f sensor.yaml
```
Which contains:
```
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: webhook
spec:
  template:
    serviceAccountName: operate-workflow-sa
  dependencies:
    - name: test-dep
      eventSourceName: webhook
      eventName: example
  triggers:
    - template:
        name: webhook-workflow-trigger
        k8s:
          operation: create
          source:
            resource:
              apiVersion: argoproj.io/v1alpha1
              kind: Workflow
              metadata:
                generateName: webhook
              spec:
                entrypoint: cowsay
                arguments:
                  parameters:
                    - name: message
                      # the value will get overridden by event payload from test-dep
                      value: hello world
                templates:
                  - name: cowsay
                    inputs:
                      parameters:
                        - name: message
                    container:
                      image: rancher/cowsay:latest
                      command: [ cowsay ]
                      args: [ "{{inputs.parameters.message}}" ]
              parameters:
                - src:
                    dependencyName: test-dep
                    dataKey: body
                  dest: spec.arguments.parameters.0.value
```
### Trigger the workflow via webhook
```
curl -d '{"message":"this is my first webhook"}' -H "Content-Type:application/json" -X POST http://localhost:12000/example
```
## Troubleshooting
### Controller Manager fails to start
```
{"level":"fatal","ts":"2026-02-25T09:06:09.909611012Z","logger":"argo-events.eventbus-controller","caller":"cmd/start.go:192","msg":"Unable to start controller manager","error":"failed to wait for eventbus-controller caches to sync: timed out waiting for cache to be synced for Kind *v1alpha1.EventBus","stacktrace":"github.com/argoproj/argo-events/pkg/reconciler/cmd.Start\n\t/home/runner/work/argo-events/argo-events/pkg/reconciler/cmd/start.go:192\ngithub.com/argoproj/argo-events/cmd/commands.NewControllerCommand.func1\n\t/home/runner/work/argo-events/argo-events/cmd/commands/controller.go:34\ngithub.com/spf13/cobra.(*Command).execute\n\t/home/runner/go/pkg/mod/github.com/spf13/cobra@v1.9.1/command.go:1019\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\t/home/runner/go/pkg/mod/github.com/spf13/cobra@v1.9.1/command.go:1148\ngithub.com/spf13/cobra.(*Command).Execute\n\t/home/runner/go/pkg/mod/github.com/spf13/cobra@v1.9.1/command.go:1071\ngithub.com/argoproj/argo-events/cmd/commands.Execute\n\t/home/runner/work/argo-events/argo-events/cmd/commands/root.go:19\nmain.main\n\t/home/runner/work/argo-events/argo-events/cmd/main.go:8\nruntime.main\n\t/opt/hostedtoolcache/go/1.24.2/x64/src/runtime/proc.go:283"}
```
* Make the controller manager setup dependent on the argo misc events manifests.
* Tilt example:
```
k8s_resource(new_name='events-misc', resource_deps = ['argo-events:namespace'], labels=['argo-events'],
    objects = [
        'eventbus.argoproj.io:customresourcedefinition',
        'eventsources.argoproj.io:customresourcedefinition',
        'sensors.argoproj.io:customresourcedefinition',
        'argo-events-sa:serviceaccount',
        'argo-events-aggregate-to-admin:clusterrole',
        'argo-events-aggregate-to-edit:clusterrole',
        'argo-events-aggregate-to-view:clusterrole',
        'argo-events-role:clusterrole',
        'argo-events-binding:clusterrolebinding',
        'argo-events-controller-config:configmap',
    ],
)
```

### Build Failed: kubernetes apply: error mapping argoproj.io/EventBus: no matches for kind "EventBus" in version "argoproj.io/v1alpha1"
* Use `kubectl api-resources | greo argo` and see if `EventBus` is present.
* It seems the installation didn't insteall the `EventBus` Custom Resource Definition (CRD).
* Make the event bus setup dependent on the argo events manifests.

### admission webhook "webhook.argo-events.argoproj.io" denied the request
```
Build Failed: admission webhook "webhook.argo-events.argoproj.io" denied the request: failed to get EventBus eventBusName=default; err=eventbus.argoproj.io "default" not found
```
* Make sure your sensor is in the correct namespace