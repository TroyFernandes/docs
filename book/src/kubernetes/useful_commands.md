# Useful Commands

### Get all running namespaces
`kubectl get svc --all-namespaces -o wide`

### Create a deployment
`kubectl create -f [filename.yml]`

### Delete a deployment
`kubectl delete -f [filename.yml]`

### Stop pod by namespace
`kubectl delete --all pods --namespace=[namespace]`

### Stop deployment by namespace
`kubectl delete --all deployments --namespace=firefox`

### Switch to namespace
`kubectl config set-context --current --namespace=my-namespace`

### Edit Deployment
`kubectl edit deployment/my-nginx`

### Restart Deployment
`kubectl rollout restart deployment <deployment_name> -n <namespace>`

### Delete Service
`kubectl delete service kubernetes-dashboard -n kube-system`

### Delete namespace
`kubectl delete ns cattle-system`

