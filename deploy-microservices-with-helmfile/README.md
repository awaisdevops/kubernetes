## Demo Project - Deploy Microservices with Helmfile

### Topics of the Demo Project
Deploy Microservices with Helmfile

### Technologies Used
- Kubernetes
- Helm
- Helmfile

### Project Description
- Deploy Microservices with Helm
- Deploy Microservices with Helmfile

#### Steps to deploy microservices with helm
To install the microservices, we can either manually execute a `helm install` command for each service like
```sh
helm install -f values/redis-values.yaml rediscart helmcharts/redis
# =>
# NAME: rediscart
# LAST DEPLOYED: Sun May  7 20:16:28 2023
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None

helm install -f values/email-service-values.yaml emailservice helmcharts/shop
# =>
# NAME: emailservice
# LAST DEPLOYED: Sun May  7 20:16:37 2023
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None

...
```

or you can create a shell script `install-online-shop.sh` containing all these commands:

_install-online-shop.sh_
```sh
helm install -f values/redis-values.yaml rediscart helmcharts/redis

helm install -f values/email-service-values.yaml emailservice helmcharts/shop
helm install -f values/cart-service-values.yaml cartservice helmcharts/shop
helm install -f values/currency-service-values.yaml currencyservice helmcharts/shop
helm install -f values/payment-service-values.yaml paymentservice helmcharts/shop
helm install -f values/recommendation-service-values.yaml recommendationservice helmcharts/shop
helm install -f values/productcatalog-service-values.yaml productcatalogservice helmcharts/shop
helm install -f values/shipping-service-values.yaml shippingservice helmcharts/shop
helm install -f values/ad-service-values.yaml adservice helmcharts/shop
helm install -f values/checkout-service-values.yaml checkoutservice helmcharts/shop
helm install -f values/frontend-values.yaml frontend helmcharts/shop
```

and execute it:
```sh
chmod 755 install-online-shop.sh
./install-online-shop.sh

helm ls
# NAME                 	NAMESPACE	REVISION	UPDATED                              	STATUS  	CHART             	APP VERSION
# adservice            	default  	1       	2023-05-07 20:16:37.38239 +0200 CEST 	deployed	microservice-0.1.0	1.16.0     
# cartservice          	default  	1       	2023-05-07 20:16:30.389721 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
# checkoutservice      	default  	1       	2023-05-07 20:16:38.531273 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
# currencyservice      	default  	1       	2023-05-07 20:16:31.378584 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
# emailservice         	default  	1       	2023-05-07 20:16:29.401306 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
# frontend          	default  	1       	2023-05-07 20:16:39.663172 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
# paymentservice       	default  	1       	2023-05-07 20:16:32.192593 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
# productcatalogservice	default  	1       	2023-05-07 20:16:34.922954 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
# recommendationservice	default  	1       	2023-05-07 20:16:33.589119 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
# rediscart            	default  	1       	2023-05-07 20:16:28.415581 +0200 CEST	deployed	redis-0.1.0       	1.16.0     
# shippingservice      	default  	1       	2023-05-07 20:16:35.988281 +0200 CEST	deployed	microservice-0.1.0	1.16.0     
```

To uninstall the services we have to execute a `helm uninstall` command for each service or can put all these commands into an according shell script:

_uninstall-online-shop.sh_
```sh
helm uninstall frontend
helm uninstall checkoutservice
helm uninstall adservice
helm uninstall shippingservice
helm uninstall productcatalogservice
helm uninstall recommendationservice
helm uninstall paymentservice
helm uninstall currencyservice
helm uninstall cartservice
helm uninstall emailservice

helm uninstall rediscart
```

```sh
chmod 755 uninstall-online-shop.sh
./uninstall-online-shop.sh
# release "frontend" uninstalled
# release "checkoutservice" uninstalled
# release "adservice" uninstalled
# release "shippingservice" uninstalled
# release "productcatalogservice" uninstalled
# release "recommendationservice" uninstalled
# release "paymentservice" uninstalled
# release "currencyservice" uninstalled
# release "cartservice" uninstalled
# release "emailservice" uninstalled
# release "rediscart" uninstalled

helm ls
# NAME  NAMESPACE  REVISION  UPDATED  STATUS  CHART  APP  VERSION
```

#### Steps to deploy the microservices with helmfile
**Step 1:** Install helmfile\
To deploy Helm Charts using a helmfile, you need to install the command line tool `helmfile`. On a Mac this can be done with homebrew:
```sh
brew update
brew install helmfile
```

See the [Documentation](https://github.com/helmfile/helmfile) for other ways of installing it.

**Step 2:** Create a Helmfile\
Create a file called `helmfile.yaml` with the following content:

_helmfile.yaml_
```yaml
releases:
  - name: rediscart
    chart: helmcharts/redis
    values: 
      - values/redis-values.yaml
      - replicaCount: 1
      - volumeName: "redis-cart-data"
  
  - name: emailservice
    chart: helmcharts/shop
    values:
      - values/email-service-values.yaml

  - name: cartservice
    chart: helmcharts/shop
    values:
      - values/cart-service-values.yaml    

  - name: currencyservice
    chart: helmcharts/shop
    values:
      - values/currency-service-values.yaml   

  - name: paymentservice
    chart: helmcharts/shop
    values:
      - values/payment-service-values.yaml

  - name: recommendationservice
    chart: helmcharts/shop
    values:
      - values/recommendation-service-values.yaml

  - name: productcatalogservice
    chart: helmcharts/shop
    values:
      - values/productcatalog-service-values.yaml

  - name: shippingservice
    chart: helmcharts/shop
    values:
      - values/shipping-service-values.yaml

  - name: adservice
    chart: helmcharts/shop
    values:
      - values/ad-service-values.yaml

  - name: checkoutservice
    chart: helmcharts/shop
    values:
      - values/checkout-service-values.yaml

  - name: frontend
    chart: helmcharts/shop
    values:
      - values/frontend-values.yaml
```

**Step 3:** Synchronize the Helmfile with the K8s cluster\
To synchronize the K8s cluster with the desired state declared in the helmfile.yaml, execute 
```sh
helmfile sync
# Building dependency release=currencyservice, chart=helmcharts/shop
# ...
# Building dependency release=recommendationservice, chart=helmcharts/shop
# Upgrading release=rediscart, chart=helmcharts/redis
# ...
# Upgrading release=recommendationservice, chart=helmcharts/shop
# Release "cartservice" does not exist. Installing it now.
# NAME: cartservice
# LAST DEPLOYED: Sun May  7 20:39:59 2023
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# ...
# UPDATED RELEASES:
# NAME                    CHART              VERSION   DURATION
# cartservice             helmcharts/shop    0.1.0           2s
# adservice               helmcharts/shop    0.1.0           2s
# currencyservice         helmcharts/shop    0.1.0           2s
# shippingservice         helmcharts/shop    0.1.0           2s
# recommendationservice   helmcharts/shop    0.1.0           2s
# checkoutservice         helmcharts/shop    0.1.0           2s
# rediscart               helmcharts/redis   0.1.0           2s
# paymentservice          helmcharts/shop    0.1.0           3s
# emailservice            helmcharts/shop    0.1.0           2s
# frontend                helmcharts/shop    0.1.0           2s
# productcatalogservice   helmcharts/shop    0.1.0           4s
```

To get the status of all the releases declared in the helmfile.yaml, execute
```sh
helmfile status
# Getting status rediscart
# Getting status recommendationservice
# ...
# Getting status productcatalogservice
# NAME: rediscart
# LAST DEPLOYED: Sun May  7 20:39:59 2023
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# 
# NAME: currencyservice
# LAST DEPLOYED: Sun May  7 20:39:59 2023
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# ...
```

To uninstall all the releases declared in the helmfile.yaml with on command, execute
```sh
helmfile destroy
# Building dependency release=currencyservice, chart=helmcharts/shop
# Building dependency release=paymentservice, chart=helmcharts/shop
# ...
# Deleting frontend
# Deleting adservice
# ...
# Deleting cartservice
# release "adservice" uninstalled
# release "paymentservice" uninstalled
# ...
# release "cartservice" uninstalled
# 
# DELETED RELEASES:
# NAME                    DURATION
# adservice                     1s
# paymentservice                1s
# shippingservice               1s
# productcatalogservice         1s
# recommendationservice         1s
# frontend                      2s
# checkoutservice               2s
# emailservice                  2s
# rediscart                     2s
# cartservice                   2s
```
