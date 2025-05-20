## Demo Project - Deploy Image from Private Docker Registry

### Topics of the Demo Project
Deploy our web application in K8s cluster from private Docker registry

### Technologies Used
- Kubernetes
- Helm
- AWS ECR
- Docker

### Project Description
- Create Secret for credentials for the private Docker registry
- Configure the Docker registry secret in application Deployment component
- Deploy web application image from our private Docker registry in K8s cluster

#### Steps to create a Secret with credentials for the private Docker registry
To create a Secret holding the credentials for docker-login, we need the base64 encoded content of the `~/.docker/config.json` file. To get that file for our private AWS ECR registry, we have to login to that registry. We can either get the password and the do a docker login like this: 
```sh
aws ecr get-login-password --region eu-central-1
# => pwd: eyJwYXlsb2FkI.....ODI2NjgyMDF9
docker login -u AWS -p eyJwYXlsb2FkI.....ODI2NjgyMDF9 369076538622.dkr.ecr.eu-central-1.amazonaws.com
```

or we can directly execute the following command:
```sh
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 369076538622.dkr.ecr.eu-central-1.amazonaws.com
```

We find this command in the AWS management web console. Navigate to Amazon ECR > Repositories, click on your repository and press the "View push commands" button.

The second way is the preferred one because we don't have to type in our ECR password in the command line (ending up having it in the command line history).

Executing the above docker-login command created an entry in the file `~/.docker/config.json` that looks like this:
```json
{
    "auths": {
        "369076538622.dkr.ecr.eu-central-1.amazonaws.com": {},
    },
    "credsStore": "osxkeychain"
}
```

If we put this content base64 encoded into the Secret component, we won't be able to use it in our minikube cluster, because the minikube cluster is running in its own docker container and does not have access to the osx keychain. So we have to execute the docker-login command from within the minikube container.

```sh
minikube ssh

pwd
# => /home/docker

docker login -u AWS -p eyJwYXlsb2FkI.....ODI2NjgyMDF9 369076538622.dkr.ecr.eu-central-1.amazonaws.com
cat .docker/config.json
# =>
# {
# 	"auths": {
# 		"369076538622.dkr.ecr.eu-central-1.amazonaws.com": {
# 			"auth": "QVdTOmV5SndZWGxzYjJGa0lqb2.....ESTFPRFEyT1RWOQ=="
# 		}
# 	}
# }

exit
```

Now we have to copy that config.json from the minikube container to our ~/.docker folder:
```sh
scp -i $(minikube ssh-key) docker@$(minikube ip):.docker/config.json ~/.docker/config.json
```

****
Note: This command does not work with minikube running in a docker container. You won't be able to connect to the IP address returned by `minikube ip`. To get the content we have to either copy it manually or mount a directory into minikube:
```sh
minikube mount ~/.docker:/home/docker/.docker

minikube ssh
docker login -u AWS -p eyJwYXlsb2FkI.....ODI2NjgyMDF9 369076538622.dkr.ecr.eu-central-1.amazonaws.com
exit

cat ~/.docker/config.json
```
****

With these preparations we are ready to get the base64 encoded content of the file `~/.docker/config.json` and create a Secret from it:
```sh
cat ~/.docker/config.json | base64
# => ewoJImF1dGhzIjog.....IgoJCX0KCX0KfQ==
```

Create a file called `docker-secret.yaml` with the following content:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-registry-key
data:
  .dockerconfigjson: ewoJImF1dGhzIjog.....IgoJCX0KCX0KfQ==
type: kubernetes.io/dockerconfigjson
```

Apply it with `kubectl apply -f docker-secret.yaml`.

Another way of creating the Secret, once we have the config.json file, is to use the following kubectl command:
```sh
kubectl create secret generic my-registry-key-2 \
  --from-file=.dockerconfigjson=.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

And finally we can also combine the docker login command with the create secret command:
```sh
kubectl create secret docker-registry my-registry-key-3 \
  --docker-server=369076538622.dkr.ecr.eu-central-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=eyJwYXlsb2FkI.....ODI2NjgyMDF9
```

This last command does a login to the private docker registry using the given username and password and creates a Secret containing the base64 encoded content of the config.json file that would have been created by a regular `docker login` command. Even if this last way of creating the secret is the most comfortable one, be aware that you cannot create a secret containing the credentials for multiple registries. With the previous two ways you can login to multiple docker registries resulting in a config.json file that contains the credentials for all of them. 

#### Steps to configure the Docker registry secret in application Deployment component
Create a file called `user-profile-deployment.yaml` with the following content:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-profile
  labels:
    app: user-profile
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-profile
  template:
    metadata:
      labels:
        app: user-profile
    spec:
      imagePullSecrets:
      - name: my-registry-key
      containers:
      - name: user-profile
        image: 369076538622.dkr.ecr.eu-central-1.amazonaws.com/user-profile:1.0.0
        imagePullPolicy: Always
        ports:
          - containerPort: 3000
```

#### Steps to deploy the web application image from the private Docker registry in our K8s cluster
Apply the deployment configuration file to the cluster:
```sh
kubectl apply -f user-profile-deployment.yaml

# check whether the image was pulled successfully
kubectl get pods
# =>
# NAME                              READY   STATUS    RESTARTS   AGE
# user-profile-696755958d-pvb27     1/1     Running   0          13s

kubectl describe pod user-profile-696755958d-pvb27
# => Events show you whether the image was pulled successfully or not
# Events:
#   Type    Reason     Age   From               Message
#   ----    ------     ----  ----               -------
#   Normal  Scheduled  17s   default-scheduler  Successfully assigned default/user-profile-696755958d-pvb27 to minikube
#   Normal  Pulling    17s   kubelet            Pulling image "369076538622.dkr.ecr.eu-central-1.amazonaws.com/user-profile:1.0.0"
#   Normal  Pulled     18s   kubelet            Successfully pulled image "369076538622.dkr.ecr.eu-central-1.amazonaws.com/user-profile:1.0.0" in 572.715625ms (572.7335ms including waiting)
#   Normal  Created    19s   kubelet            Created container user-profile
#   Normal  Started    19s   kubelet            Started container user-profile
```
