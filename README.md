# infra terraform
- VPC
- EC2
- EKS
- ECR
- Jenkins
# setup AWS Systems Manager
- Parameter Store: {project}-{env}-github-token
# deploy scenario
- vpc
- jenkins
- ecr
- eks
    - eks
    - argo
# terraform commands
## init 
```terraform init```
## plan
```terraform plan```
## apply
```terraform apply --auto-approve```
## destroy
```terraform destroy --auto-approve```
## ArgoCD
- Port forwarding
```kubectl port-forward svc/argocd-server -n argocd 8080:443```
- admin password
```kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d```
## Jenkins
- setup permission
```sudo usermod -aG docker jenkins```
- check command
```sudo su - jenkins```
```docker ps```
```sudo systemctl restart jenkins```