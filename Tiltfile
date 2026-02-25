load('ext://namespace', 'namespace_yaml', 'namespace_inject')
k8s_yaml(namespace_yaml('argocd'), allow_duplicates=False)
k8s_resource(new_name='argocd:namespace', objects=['argocd:namespace'], labels = ['argocd'])

k8s_yaml(namespace_inject(kustomize('argocd'), 'argocd'))

#port_forward(8081, 443, name="argocd-ui", host="0.0.0.0")

# gather all resources
k8s_resource(workload='argocd-server', resource_deps = ['argocd:namespace'],
    port_forwards=['0.0.0.0:8081:8080'],
    labels = ['argocd']
)
k8s_resource(workload='argocd-applicationset-controller', resource_deps = ['argocd:namespace'], labels = ['argocd'])
k8s_resource(workload='argocd-dex-server', resource_deps = ['argocd:namespace'], labels = ['argocd'])
k8s_resource(workload='argocd-notifications-controller', resource_deps = ['argocd:namespace'], labels = ['argocd'])
k8s_resource(workload='argocd-redis', resource_deps = ['argocd:namespace'], labels = ['argocd'])
k8s_resource(workload='argocd-repo-server', resource_deps = ['argocd:namespace'], labels = ['argocd'])
k8s_resource(workload='argocd-application-controller', resource_deps = ['argocd:namespace'], labels = ['argocd'])
k8s_resource(new_name='argocd-misc',
    objects = [
       'applications.argoproj.io:customresourcedefinition',
       'applicationsets.argoproj.io:customresourcedefinition',
       'appprojects.argoproj.io:customresourcedefinition',
       'argocd-application-controller:serviceaccount',
       'argocd-applicationset-controller:serviceaccount',
       'argocd-dex-server:serviceaccount',
       'argocd-notifications-controller:serviceaccount',
       'argocd-redis:serviceaccount',
       'argocd-repo-server:serviceaccount',
       'argocd-server:serviceaccount',
       'argocd-application-controller:role',
       'argocd-applicationset-controller:role',
       'argocd-dex-server:role',
       'argocd-notifications-controller:role',
       'argocd-redis:role',
       'argocd-server:role',
       'argocd-application-controller:clusterrole',
       'argocd-applicationset-controller:clusterrole',
       'argocd-server:clusterrole',
       'argocd-application-controller:rolebinding',
       'argocd-applicationset-controller:rolebinding',
       'argocd-dex-server:rolebinding',
       'argocd-notifications-controller:rolebinding',
       'argocd-redis:rolebinding',
       'argocd-server:rolebinding',
       'argocd-application-controller:clusterrolebinding',
       'argocd-applicationset-controller:clusterrolebinding',
       'argocd-server:clusterrolebinding',
       'argocd-cm:configmap',
       'argocd-cmd-params-cm:configmap',
       'argocd-gpg-keys-cm:configmap',
       'argocd-notifications-cm:configmap',
       'argocd-rbac-cm:configmap',
       'argocd-ssh-known-hosts-cm:configmap',
       'argocd-tls-certs-cm:configmap',
       'argocd-notifications-secret:secret',
       'argocd-secret:secret',
       'argocd-application-controller-network-policy:networkpolicy',
       'argocd-applicationset-controller-network-policy:networkpolicy',
       'argocd-dex-server-network-policy:networkpolicy',
       'argocd-notifications-controller-network-policy:networkpolicy',
       'argocd-redis-network-policy:networkpolicy',
       'argocd-repo-server-network-policy:networkpolicy',
       'argocd-server-network-policy:networkpolicy',
    ],
    resource_deps = ['argocd:namespace'],
    labels = ['argocd']
)

# needs to wait for the argocd namespace to exist so we inject this command in to the local_resources that depend on argocd:namespace and also need the password from the configmap
initial_secret='$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)'


local_resource(name = 'patch-user', cmd = 'kubectl patch cm -n argocd argocd-cm --patch-file ./argocd/user-patch.yaml',
    labels=['user-setup'],
    resource_deps=['argocd-server'],
)

local_resource(name = 'cli login', cmd = 'argocd login localhost:8081 --insecure --username admin --password ' + str(initial_secret),
    resource_deps=['patch-user', 'argocd:namespace'],
    labels=['user-setup'],
)

local_resource(name = 'Update user password',
    cmd = 'argocd account update-password --account developer --new-password Developer123 --current-password ' + str(initial_secret),
    resource_deps=['cli login','argocd:namespace'],
    labels=['user-setup'],
)

# Apply the rbac policy patch:
k8s_custom_deploy ( 'Patch RBAC Policy',
    apply_cmd='kubectl patch cm -n argocd argocd-rbac-cm --patch-file ./argocd/developer-rbac-patch.yaml 1>&2',
    delete_cmd='kubectl -n argocd delete argocd-rbac-cm',
    deps=['argocd-server', 'Update user password'],
)
k8s_resource('Patch RBAC Policy', labels=['user-setup'], resource_deps=['argocd-server'])

include('workflow.Tiltfile')

include('rollouts.Tiltfile')

include('events.Tiltfile')