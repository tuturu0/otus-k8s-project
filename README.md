# Используемые инструменты:
- YC managed k8s
- YC s3
- Loki
- Promtail
- Prometheus
- Grafana
- Gitlab

# Проверить сервисы можно по адресам:
- Google Online Boutique http://158.160.173.116/
- Grafana, Loki, Prometheus, Алертинг http://158.160.173.116/grafana

# Для создания кластера k8s в YC необходимо запустить bash-скрипт `cluster.sh`, заполнив переменные в нём:
```bash
bash cluster.sh
```

# Для деплоя микросервисов Google Online Boutique необходимо склонировать данный репозиторий в Gitlab и запустить джобу `deploy_payload` в пайплайне:
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/1.png)
- В конце успешного выполнения джобы можно будет увидеть адресс ингресса `http://158.160.173.116/`, по которому можно будет перейти и проверить рабоспособность сервиса
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/2.png)
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/3.png)

# Для логирования используются Loki, Promtail и Grafana. Доступ к Grafana находится по адрессу `http://158.160.173.116/grafana`:
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/4.png)
<br></br>
- Как можно увидеть из скриншота ниже, Loki благополучно собирает логи
<br></br>
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/5.png)
<br></br>
- Даные Loki хранятся в YC-s3
<br></br>
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/12.png)

# Для сбора метрик используется Prometheus, который подключен к Grafana:
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/6.png)
<br></br>
- Также в данном репозитории лежит дашборд `logging-monitoring/dashboard.json`, который можно импортировать в Grafana
- На `http://158.160.173.116/grafana` данный дашборд уже импортирован
<br></br>
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/7.png)

# Для алертинга используются встроенные средства Grafana:
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/8.png)
<br></br>
- Contact points и политика настроны на отправку алертов в telegram-бота
<br></br>
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/9.png)

# Для деплоя описанных выше средств логирования и мониторинга в пайплайне описана джоба `deploy_monitoring`:
- Перед её запуском необходимо указать всои значения ключей и доменных имён/адресов в `values`
<br></br>
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/10.png)
![alt text](https://github.com/tuturu0/otus-k8s-project/blob/main/images/11.png)
# Если требуется запустить проект вручную, необходимо выполнить шаги ниже:
- Склонировать данный репозиторий
- Установить ингресс
```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace -f ./ingress/ingress-nginx-values.yaml
```
- Применить манифесты Google Online Boutique
```bash
kubectl create namespace payload
kubectl apply -f ./microservices-demo/release/kubernetes-manifests.yaml --create-namespace -n payload
```
- Применить манифест ингресса для сервиса frontend
```bash
kubectl apply -f ./ingress/frontend.yaml
```
- Для логирования необходимо заполнить `values` и выполнить
```bash
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update
helm upgrade --install loki grafana/loki -n infra --create-namespace -f ./logging-monitoring/loki-values.yaml
helm upgrade --install promtail grafana/promtail -n infra -f ./logging-monitoring/promtail-values.yaml
helm upgrade --install grafana grafana/grafana -n infra -f ./logging-monitoring/grafana-values.yaml
```
- Для мониторинга
```bash
helm upgrade --install prometheus oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack -n infra -f prometheus-values.yaml
```
- Ингресс для Grafana
```bash
kubectl apply -f ./ingress/grafana-ingress.yaml
```
