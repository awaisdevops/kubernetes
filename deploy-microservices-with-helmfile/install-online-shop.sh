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