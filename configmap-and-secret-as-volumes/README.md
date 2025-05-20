# Configuring ConfigMap and Secret Components as Volumes Inside Pods/Containers 

In this guide, I explained that **ConfigMap** and **Secret** in Kubernetes are used to create key-value pairs for environmental variables or configuration files that can be passed to applications. These are common in services that require external configuration files. Additionally, **ConfigMap** and **Secret** are actually considered volume types in Kubernetes.

---

# Configuration Files for Mosquitto Deployment, Secret, and ConfigMap Components:


## ConfigMap: `mosquitto-configmap.yaml`

```yaml
apiVersion: v1  # #apiVersion
kind: ConfigMap  # #ConfigMap
metadata:  # #metadata
  name: mosquitto-config-file  # #name
data:  # #data
  mosquitto.conf: |  # #configFileName
    log_dest stdout  # #configEntry
    log_type all  # #configEntry
    log_timestamp true  # #configEntry
    listener 9001  # #configEntry
```

---

## Deployment: `mosquitto-deployment.yaml`

```yaml
apiVersion: apps/v1  # #apiVersion
kind: Deployment  # #Deployment
metadata:  # #metadata
  name: mosquitto  # #name
  labels:  # #labels
    app: mosquitto  # #app
spec:  # #spec
  replicas: 1  # #replicas
  selector:  # #selector
    matchLabels:  # #matchLabels
      app: mosquitto  # #app
  template:  # #template
    metadata:  # #metadata
      labels:  # #labels
        app: mosquitto  # #app
    spec:  # #spec
      containers:  # #containers
        - name: mosquitto  # #name
          image: eclipse-mosquitto:1.6.2  # #image
          ports:  # #ports
            - containerPort: 1883  # #containerPort
          volumeMounts:  # #volumeMounts
            - name: mosquitto-conf  # #name
              mountPath: /mosquitto/config  # #mountPath
            - name: mosquitto-secret  # #name
              mountPath: /mosquitto/secret  # #mountPath
              readOnly: true  # #readOnly
      volumes:  # #volumes
        - name: mosquitto-conf  # #name
          configMap:  # #configMap
            name: mosquitto-config-file  # #name
        - name: mosquitto-secret  # #name
          secret:  # #secret
            secretName: mosquitto-secret-file  # #secretName
```

---

## Secret: `mosquitto-secret.yaml`

```yaml
apiVersion: v1  # #apiVersion
kind: Secret  # #Secret
metadata:  # #metadata
  name: mosquitto-secret-file  # #name
type: Opaque  # #type
data:  # #data
  secret.file: |  # #secret.file
    c29tZXN1cGVyc2VjcmV0IGZpbGUgY29udGVudHMgbm9ib2R5IHNob3VsZCBzZWU=  # #base64EncodedData
```

---

## Crete the Components

```bash
kubectl apply -f mosquitto-secret.yaml
kubectl apply -f mosquitto-configmap.yaml
kubectl apply -f mosquitto-deployment.yaml
```
## Get the Components

```bash
kubectl get pods
# NAME                         READY   STATUS              RESTARTS   AGE
# mosquitto-65f5cbcbc5-cxhvj   0/1     ContainerCreating   0          4s

kubectl get pod mosquitto-65f5cbcbc5-55x7c --watch
# NAME                         READY   STATUS              RESTARTS   AGE
# mosquitto-65f5cbcbc5-cxhvj   0/1     ContainerCreating   0          7s
# mosquitto-65f5cbcbc5-55x7c   1/1     Running             0          15s
```

## Enter the mosquitto container and check the content of the secret file:

```sh
kubectl exec -it mosquitto-65f5cbcbc5-55x7c -- /bin/sh
  cat /mosquitto/secret/secret.file
  # => some supersecret file contents nobody should see
  exit
```
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
