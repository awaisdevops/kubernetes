## Demo Project - Create Helm Chart for Microservices

### Topics of the Demo Project
Create a Helm Chart for the Online-Shop Microservices

### Technologies Used
- Kubernetes
- Helm

### Project Description
- Create 1 shared Helm Chart for all microservices, to reuse common Deployment and Service configurations for the services

#### Steps to create 1 shared Helm Chart for all microservices
We will create one Helm Chart for all the online-shop microservices except for the redis cart microservice, for which we create a separate chart.

**Step 1:** Create the directory structure
```sh
mkdir helmcharts
cd helmcharts

helm create shop
rm -r shop/templates/*.*
rm -rf shop/templates/tests
echo '' > shop/values.yaml

helm create redis
rm -r redis/templates/*.*
rm -rf redis/templates/tests
echo '' > redis/values.yaml
```

**Step 2:** Create a template file for the Deployments of the shop microservices\
Create a file `shop/templates/deployment.yaml` with the following content:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Release.Name }}
        image: {{ .Values.image }}:{{ .Values.imageVersion }}
        ports:
        - containerPort: {{ .Values.containerPort }}
        env:
        {{- range .Values.containerEnvVars }}
        - name: {{ .name }}
          value: {{ .value | quote }}
        {{- end }}
        readinessProbe:
          initialDelaySeconds: {{ .Values.readinessProbeInitialDelaySeconds }}
          periodSeconds: {{ .Values.readinessProbePeriodSeconds }}
          {{- if eq .Values.readinessProbeType "exec" }}
          exec:
            command: [{{ .Values.readinessProbeCommand | quote }}, {{ .Values.readinessProbeArg | quote }}]
          {{- else if eq .Values.readinessProbeType "httpGet" }}
          httpGet:
            path: {{ .Values.readinessProbeHttpGetPath | quote }}
            port: {{ .Values.readinessProbeHttpGetPort }}
            httpHeaders:
            {{- range .Values.readinessProbeHttpGetHeaders }}
            - name: {{ .name | quote }}
              value: {{ .value | quote }}
            {{- end }}
          {{- else if eq .Values.readinessProbeType "tcpSocket" }}
          tcpSocket:
            port: {{ .Values.readinessProbeTcpSocketPort }}
          {{- else }}
            exec:
              command: ["echo", "'OK'"]
          {{- end }}
        livenessProbe:
          initialDelaySeconds: {{ .Values.livenessProbeInitialDelaySeconds }}
          periodSeconds: {{ .Values.livenessProbePeriodSeconds }}
          {{- if eq .Values.livenessProbeType "exec" }}
          exec:
            command: [{{ .Values.livenessProbeCommand | quote }}, {{ .Values.livenessProbeArg | quote }}]
          {{- else if eq .Values.livenessProbeType "httpGet" }}
          httpGet:
            path: {{ .Values.livenessProbeHttpGetPath | quote }}
            port: {{ .Values.livenessProbeHttpGetPort }}
            httpHeaders:
            {{- range .Values.livenessProbeHttpGetHeaders }}
            - name: {{ .name | quote }}
              value: {{ .value | quote }}
            {{- end }}
          {{- else if eq .Values.livenessProbeType "tcpSocket" }}
          tcpSocket:
            port: {{ .Values.livenessProbeTcpSocketPort }}
          {{- else }}
            exec:
              command: ["echo", "'OK'"]
          {{- end }}
        resources:
          requests:
            cpu: {{ .Values.cpuRequests }}
            memory: {{ .Values.memoryRequests }}
          limits:
            cpu: {{ .Values.cpuLimits }}
            memory: {{ .Values.memoryLimits }}
```

**Step 3:** Create a template file for the Services of the shop microservices\
Create a file `shop/templates/service.yaml` with the following content:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  type: {{ .Values.serviceType }}
  selector:
    app: {{ .Release.Name }}
  ports:
  - protocol: TCP
    port: {{ .Values.servicePort }}
    targetPort: {{ .Values.containerPort }}
```

**Step 4:** Create a values file containing the default values for the shop microservices\
Create a file `shop/values.yaml` with the following content:
```yaml
# Deployment default values
# -------------------------
replicaCount: 2
image: gcr.io/google-samples/microservices-demo/servicename
imageVersion: v0.6.0

containerPort: 8080
containerEnvVars:
- name: ENV_VAR_ONE
  value: "value-one"
- name: ENV_VAR_TWO
  value: "value-two"  

readinessProbeInitialDelaySeconds: 0
readinessProbePeriodSeconds: 5
readinessProbeType: "exec"
readinessProbeCommand: "/bin/grpc_health_probe"
readinessProbeArg: "-addr=:8080"
# default values for readinessProbeType "httpGet"
readinessProbeHttpGetPath: "/_healthz"
readinessProbeHttpGetPort: 8080
readinessProbeHttpGetHeaders:
- name: "Cookie"
  value: "shop_session-id=x-readiness-probe"
# default values for readinessProbeType "tcpSocket"
readinessProbeTcpSocketPort: 8080

livenessProbeInitialDelaySeconds: 0
livenessProbePeriodSeconds: 5
livenessProbeType: "exec"
livenessProbeCommand: "/bin/grpc_health_probe"
livenessProbeArg: "-addr=:8080"
# default values for livenessProbeType "httpGet"
livenessProbeHttpGetPath: "/_healthz"
livenessProbeHttpGetPort: 8080
livenessProbeHttpGetHeaders:
- name: "Cookie"
  value: "shop_session-id=x-liveness-probe"
# default values for livenessProbeType "tcpSocket"
livenessProbeTcpSocketPort: 8080

cpuRequests: 100m
memoryRequests: 64Mi
cpuLimits: 200m
memoryLimits: 128Mi

# Service default values
# ----------------------
serviceType: ClusterIP
servicePort: 8080
```

**Step 5:** Create a service-specific values file for the emailservice\
We are going to override the default values for each individual microservice. Let's do it for the first microservice, the emailservice. Create a `helmcharts/values/email-service-values.yaml` file with the following content:
```yaml
image: gcr.io/google-samples/microservices-demo/emailservice
containerPort: 8080
containerEnvVars:
- name: PORT
  value: "8080"
readinessProbeArg: "-addr=:8080"
livenessProbeArg: "-addr=:8080"

servicePort: 5000
```

**Step 6:** Check the correctness of the template\
Let's check whether the first microservice configuration files will be generated correctly. Go outside of the `helmcharts` directory and execute the following command:
```sh
helm template -f values/email-service-values.yaml helmcharts/shop
```

This command won't create any files. It just prints out what would be sent to Kubernetes when `helm install` would be executed. (As an alternative you could also execute `helm install --dry-run -f values/email-service-values.yaml emailservice helmcharts/shop`).

There is also a `helm lint` command that examines a chart for possible issues. Issues reported as ERROR will cause the chart to fail on installation. Issues reported as WARNING just break the conventions or recommendations.
```sh
helm lint -f values/email-service-values.yaml helmcharts/shop
# ==> Linting helmcharts/shop
# [INFO] Chart.yaml: icon is recommended

# 1 chart(s) linted, 0 chart(s) failed
```

**Step 7:** Create service-specific values files for all the other microservices\
Create the following files inside the `values/` folder:

_ad-service-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/adservice
containerPort: 9555
containerEnvVars:
- name: PORT
  value: "9555"
readinessProbeInitialDelaySeconds: 20
readinessProbePeriodSeconds: 15
readinessProbeArg: "-addr=:9555"
livenessProbeInitialDelaySeconds: 20
livenessProbePeriodSeconds: 15
livenessProbeArg: "-addr=:9555"
cpuRequests: 200m
memoryRequests: 180Mi
cpuLimits: 300m
memoryLimits: 300Mi

servicePort: 9555
```

_cart-service-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/cartservice
containerPort: 7070
containerEnvVars:
- name: PORT
  value: "7070"
- name: REDIS_ADDR
  value: "rediscart:6379"  
readinessProbeArg: "-addr=:7070"
livenessProbeArg: "-addr=:7070"
cpuRequests: 200m
cpuLimits: 300m

servicePort: 7070
```

_checkout-service-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/checkoutservice
containerPort: 5050
containerEnvVars:
- name: PORT
  value: "5050"
- name: PRODUCT_CATALOG_SERVICE_ADDR   
  value: "productcatalogservice:3550"
- name: SHIPPING_SERVICE_ADDR
  value: "shippingservice:50051"
- name: PAYMENT_SERVICE_ADDR
  value: "paymentservice:50051"    
- name: EMAIL_SERVICE_ADDR
  value: "emailservice:5000"
- name: CURRENCY_SERVICE_ADDR
  value: "currencyservice:7000"
- name: CART_SERVICE_ADDR
  value: "cartservice:7070" 
readinessProbeArg: "-addr=:5050"
livenessProbeArg: "-addr=:5050"

servicePort: 5050
```

_currency-service-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/currencyservice
containerPort: 7000
containerEnvVars:
- name: PORT
  value: "7000"
- name: DISABLE_PROFILER
  value: "true"
readinessProbeArg: "-addr=:7000"
livenessProbeArg: "-addr=:7000"

servicePort: 7000
```

_frontend-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/frontend
containerPort: 8080
containerEnvVars:
- name: PORT
  value: "8080"
- name: PRODUCT_CATALOG_SERVICE_ADDR
  value: "productcatalogservice:3550"
- name: CURRENCY_SERVICE_ADDR
  value: "currencyservice:7000"
- name: CART_SERVICE_ADDR
  value: "cartservice:7070"
- name: RECOMMENDATION_SERVICE_ADDR
  value: "recommendationservice:8080"
- name: SHIPPING_SERVICE_ADDR
  value: "shippingservice:50051"
- name: CHECKOUT_SERVICE_ADDR
  value: "checkoutservice:5050"
- name: AD_SERVICE_ADDR
  value: "adservice:9555"    
readinessProbeInitialDelaySeconds: 10
readinessProbePeriodSeconds: 10
readinessProbeType: "httpGet"
readinessProbeHttpGetPort: 8080
livenessProbeInitialDelaySeconds: 10
livenessProbePeriodSeconds: 10
livenessProbeType: "httpGet"
livenessProbeHttpGetPort: 8080

serviceType: LoadBalancer
servicePort: 80
```

_payment-service-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/paymentservice
containerPort: 50051
containerEnvVars:
- name: PORT
  value: "50051"
- name: DISABLE_PROFILER
  value: "true"
readinessProbeArg: "-addr=:50051"
livenessProbeArg: "-addr=:50051"

servicePort: 50051
```

_productcatalog-service-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/productcatalogservice
containerPort: 3550
containerEnvVars:
- name: PORT
  value: "3550"
readinessProbeArg: "-addr=:3550"
livenessProbeArg: "-addr=:3550"

servicePort: 3550
```

_recommendation-service-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/recommendationservice
containerPort: 8080
containerEnvVars:
- name: PORT
  value: "8080"
- name: PRODUCT_CATALOG_SERVICE_ADDR
  value: "productcatalogservice:3550"
readinessProbeArg: "-addr=:8080"
livenessProbeArg: "-addr=:8080"
memoryRequests: 220Mi
memoryLimits: 450Mi

servicePort: 8080
```

_shipping-service-values.yaml_
```yaml
image: gcr.io/google-samples/microservices-demo/shippingservice
containerPort: 50051
containerEnvVars:
- name: PORT
  value: "50051"
readinessProbeArg: "-addr=:50051"
livenessProbeArg: "-addr=:50051"

servicePort: 50051
```

**Step 8:** Create template files for the Deployment and Service of the redis microservice\
Create a file `redis/templates/deployment.yaml` with the following content:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Release.Name }}
        image: {{ .Values.image }}:{{ .Values.imageVersion }}
        ports:
        - containerPort: {{ .Values.containerPort }}
        volumeMounts:
        - name: {{ .Values.volumeName }}
          mountPath: {{ .Values.containerMountPath }}
        readinessProbe:
          initialDelaySeconds: {{ .Values.readinessProbeInitialDelaySeconds }}
          periodSeconds: {{ .Values.readinessProbePeriodSeconds }}
          tcpSocket:
            port: {{ .Values.readinessProbeTcpSocketPort }}
        livenessProbe:
          initialDelaySeconds: {{ .Values.livenessProbeInitialDelaySeconds }}
          periodSeconds: {{ .Values.livenessProbePeriodSeconds }}
          tcpSocket:
            port: {{ .Values.livenessProbeTcpSocketPort }}
        resources:
          requests:
            cpu: {{ .Values.cpuRequests }}
            memory: {{ .Values.memoryRequests }}
          limits:
            cpu: {{ .Values.cpuLimits }}
            memory: {{ .Values.memoryLimits }}
      volumes: 
      - name: {{ .Values.volumeName }}
        emptyDir: {}
```

Create a file `redis/templates/service.yaml` with the following content:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  type: ClusterIP
  selector:
    app: {{ .Release.Name }}
  ports:
  - protocol: TCP
    port: {{ .Values.servicePort }}
    targetPort: {{ .Values.containerPort }}
```

**Step 9:** Create a values file containing the default values for the redis microservice\
Create a file `redis/values.yaml` with the following content:
```yaml
# Deployment default values
# -------------------------
replicaCount: 1
image: redis
imageVersion: alpine

containerPort: 8080

volumeName: redis-data
containerMountPath: /data

readinessProbeInitialDelaySeconds: 0
readinessProbePeriodSeconds: 5
readinessProbeType: "tcpSocket"
readinessProbeTcpSocketPort: 8080

livenessProbeInitialDelaySeconds: 0
livenessProbePeriodSeconds: 5
livenessProbeType: "tcpSocket"
livenessProbeTcpSocketPort: 8080

cpuRequests: 100m
memoryRequests: 64Mi
cpuLimits: 200m
memoryLimits: 128Mi

# Service default values
# ----------------------
serviceType: ClusterIP
servicePort: 8080
```

**Step 10:** Create a service-specific values file for the redis cart\
Create a `helmcharts/values/redis-values.yaml` file with the following content:
```yaml
readinessProbeTcpSocketPort: 6379
livenessProbeTcpSocketPort: 6379
cpuRequests: 70m
memoryRequests: 200Mi
cpuLimits: 125m
memoryLimits: 256Mi

servicePort: 6379
```

**Step 11:** Check the correctness of the template\
Let's check whether the redis configuration files will be generated correctly. Go outside of the `helmcharts` directory and execute the following command:
```sh
helm template -f values/redis-values.yaml helmcharts/redis
```