# Demo Commands - Quick Reference

## Pre-Demo Setup
```bash
# Login to OpenShift
oc login --token=<your-token> --server=https://api.sandbox-m2.ll9k.p1.openshiftapps.com:6443

# Navigate to project directory
cd C:\Users\vomin\Documents\PrivateCloud
```

## Demo Flow Commands

### 1. Check Current Status
```bash
oc get pods
oc get svc,route
oc get hpa
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/
```

### 2. Scaling Demo
```bash
# Scale down
oc scale deployment fastapi-app --replicas=1
oc get pods -l app=fastapi-app
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/

# Scale up
oc scale deployment fastapi-app --replicas=2
oc get pods -l app=fastapi-app
```

### 3. Stress Test
```bash
.\scripts\final_stress_test.ps1
```

### 4. Health Checks
```bash
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/live
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/ready
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/startup
```

### 5. Full Redeploy (if needed)
```bash
# Clean up
oc delete all --all
oc delete configmap,secret,pvc --all

# Deploy database
oc apply -f kubernetes/db-configmap.yaml
oc apply -f kubernetes/secret.yaml
oc apply -f kubernetes/postgresql.yaml

# Build and deploy app
oc start-build fastapi-app --from-dir=src --follow
oc apply -f kubernetes/deployment.yaml
oc apply -f kubernetes/configmap.yaml
oc apply -f kubernetes/log-configmap.yaml
oc apply -f kubernetes/service.yaml
oc apply -f kubernetes/route.yaml
oc apply -f kubernetes/hpa.yaml

# Verify
oc get pods
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/
```

## Expected Results

### Stress Test Output
```
Concurrent Stress Test Results (2 pods):
======================================
Total Requests: 1000
Concurrent Connections: 20
Total Time: ~120 seconds
Requests Per Second (RPS): ~7.85
Error Rate: 0%
Latency p50: ~2073 ms
Latency p95: ~2195 ms
Latency p99: ~2438 ms
```

### Health Check Responses
```json
{"status":"ok","message":"Liveness health check passed"}
{"status":"ok","message":"Readiness health check passed"}
{"status":"ok","message":"Startup health check passed"}
```

## Troubleshooting

### Pod Not Starting
```bash
oc logs <pod-name>
oc describe pod <pod-name>
```

### Endpoint Not Responding
```bash
oc get route
curl.exe <route-url>
```

### Build Issues
```bash
oc logs build/fastapi-app-<number>
oc describe build fastapi-app-<number>
```