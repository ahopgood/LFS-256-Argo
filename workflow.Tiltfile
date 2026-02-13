load('ext://namespace', 'namespace_yaml', 'namespace_inject')
k8s_yaml(namespace_yaml('argowf'), allow_duplicates=False)
k8s_resource(new_name='argowf:namespace', objects=['argowf:namespace'], labels=['argo-workflows'])

k8s_yaml(namespace_inject(kustomize('workflows'), 'argowf'))

k8s_resource(workload='argo-server', resource_deps = ['argowf:namespace'], labels=['argo-workflows'],
    port_forwards=['0.0.0.0:2746:2746'],
)
k8s_resource(workload='workflow-controller', resource_deps = ['argowf:namespace'], labels=['argo-workflows'])
k8s_resource(new_name='argowf-misc',
    objects = [
       'clusterworkflowtemplates.argoproj.io:customresourcedefinition',
       'cronworkflows.argoproj.io:customresourcedefinition',
       'workflowartifactgctasks.argoproj.io:customresourcedefinition',
       'workfloweventbindings.argoproj.io:customresourcedefinition',
       'workflows.argoproj.io:customresourcedefinition',
       'workflowtaskresults.argoproj.io:customresourcedefinition',
       'workflowtasksets.argoproj.io:customresourcedefinition',
       'workflowtemplates.argoproj.io:customresourcedefinition',
       'argo:serviceaccount',
       'argo-server:serviceaccount',
       'argo-role:role',
       'argo-aggregate-to-admin:clusterrole',
       'argo-aggregate-to-edit:clusterrole',
       'argo-aggregate-to-view:clusterrole',
       'argo-cluster-role:clusterrole',
       'argo-server-cluster-role:clusterrole',
       'argo-binding:rolebinding',
       'argo-binding:clusterrolebinding',
       'argo-server-binding:clusterrolebinding',
       'workflow-controller-configmap:configmap',
       'workflow-controller:priorityclass'
   ],
   resource_deps = ['argowf:namespace'],
   labels=['argo-workflows']
)