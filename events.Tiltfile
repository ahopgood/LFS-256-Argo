load('ext://namespace', 'namespace_yaml', 'namespace_inject')
k8s_yaml(namespace_yaml('argo-events'), allow_duplicates=False)
k8s_resource(new_name='argo-events:namespace', objects=['argo-events:namespace'], labels=['argo-events'])

# Need to install events manifest in the `argocd` namespace
k8s_yaml(namespace_inject(kustomize('events'), 'argo-events'))
# The example projects need to go elsewhere

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

k8s_resource('controller-manager', resource_deps=['argo-events:namespace', 'events-misc'], labels=['argo-events'])

k8s_resource('events-webhook', new_name='validating-webhook', resource_deps=['argo-events:namespace'], labels=['argo-events'],
    objects = [
        'argo-events-webhook-sa:serviceaccount',
        'argo-events-webhook:clusterrole',
        'argo-events-webhook-binding:clusterrolebinding',
    ]
)

k8s_resource(new_name='eventbus', resource_deps = ['argo-events:namespace', 'events-misc'], labels=['argo-events'],
    objects = [
        'default:eventbus',
    ]
)
# Event source
k8s_resource(new_name='event-source', resource_deps = ['argo-events:namespace', 'events-misc'], labels=['argo-events'],
    objects=['webhook:eventsource'],
    port_forwards=['12000:12000'],
)

k8s_resource(new_name='workflow-rbac', resource_deps = ['argo-events:namespace', 'events-misc'], labels=['argo-events'],
    objects = [
        'executor:role',
        'executor-default:rolebinding',
    ]
)

# sensor
k8s_resource(new_name='sensor-rbac', resource_deps = ['argo-events:namespace', 'events-misc'], labels=['argo-events'],
    objects = [
        'operate-workflow-sa:serviceaccount',
        'operate-workflow-role:role',
        'operate-workflow-role-binding:rolebinding',
    ]
)

k8s_yaml(namespace_inject('events/sensor.yaml',  'argo-events'))

k8s_resource(new_name='event-sensor', resource_deps = ['argo-events:namespace', 'events-misc'], labels=['argo-events'],
    objects=['webhook:sensor'],
)