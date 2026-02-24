load('ext://namespace', 'namespace_yaml', 'namespace_inject')
k8s_yaml(namespace_yaml('argo-rollouts'), allow_duplicates=False)
k8s_resource(new_name='argo-rollouts:namespace', objects=['argo-rollouts:namespace'], labels=['argo-rollouts'])

k8s_yaml(namespace_inject(kustomize('rollouts'), 'argo-rollouts'))

k8s_resource(new_name='argo-rollouts', workload='argo-rollouts', resource_deps = ['argo-rollouts:namespace'], labels=['argo-rollouts'])

k8s_resource(new_name='argo-rollouts-misc',
    objects = [
       "analysisruns.argoproj.io:customresourcedefinition",
       "analysistemplates.argoproj.io:customresourcedefinition",
       "clusteranalysistemplates.argoproj.io:customresourcedefinition",
       "experiments.argoproj.io:customresourcedefinition",
       "rollouts.argoproj.io:customresourcedefinition",
       "argo-rollouts:serviceaccount",
       "argo-rollouts:clusterrole",
       "argo-rollouts-aggregate-to-admin:clusterrole",
       "argo-rollouts-aggregate-to-edit:clusterrole",
       "argo-rollouts-aggregate-to-view:clusterrole",
       "argo-rollouts:clusterrolebinding",
       "argo-rollouts-config:configmap",
       "argo-rollouts-notification-secret:secret",
    ],
   resource_deps = ['argo-rollouts:namespace'],
   labels=['argo-rollouts']
)