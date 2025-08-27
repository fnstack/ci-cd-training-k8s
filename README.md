# ci-cd-training-k8s

npm i -g npm bun @anthropic-ai/claude-code

git remote add gitea https://gitea.arpce.fnstack.dev/fnstack/k8s-config.git

# Installation (sur Ubuntu/Debian)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Démarrage
minikube start --driver=docker --cpus=2 --memory=2048
minikube dashboard

# Arrêt
minikube stop
minikube delete

You can now deploy:
  - All resources: kubectl apply -f k8s/ -R
  - Specific app: kubectl apply -f k8s/web-app/ or kubectl apply -f k8s/user-api/
  - Namespace first: kubectl apply -f k8s/namespace.yaml