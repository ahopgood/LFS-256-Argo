start:
	ctlptl create cluster kind --name kind-argo --registry=ctlptl-registry

delete:
	ctlptl delete cluster kind-argo --cascade=true
