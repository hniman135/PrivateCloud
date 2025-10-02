# Hướng Dẫn Demo: Private Cloud FastAPI Application

## Tổng Quan Demo
Demo này trình bày quá trình triển khai và tối ưu ứng dụng FastAPI trên Red Hat OpenShift Private Cloud, bao gồm:
- Triển khai database PostgreSQL
- Build và deploy ứng dụng FastAPI
- Horizontal scaling với HPA
- Stress testing để đo hiệu năng

**Thời gian ước tính**: 15-20 phút

## Chuẩn Bị Trước Demo
1. Mở PowerShell trong thư mục project: `C:\Users\vomin\Documents\PrivateCloud`
2. Đảm bảo đã login OpenShift: `oc login --token=<token> --server=https://api.sandbox-m2.ll9k.p1.openshiftapps.com:6443`
3. Project đã được deploy và chạy (2 pods FastAPI + 1 PostgreSQL)

## Kịch Bản Demo

### **Phần 1: Giới Thiệu và Kiến Trúc (2 phút)**

**Người thuyết trình nói:**
"Xin chào, hôm nay tôi sẽ demo dự án Private Cloud của mình. Dự án triển khai ứng dụng web FastAPI có khả năng xử lý thông lượng cao trên Red Hat OpenShift.

Kiến trúc bao gồm:
- **Compute Layer**: FastAPI pods với Gunicorn/Uvicorn, HPA cho auto-scaling
- **Storage Layer**: PostgreSQL với persistent storage, ConfigMaps/Secrets
- **Networking Layer**: OpenShift Routes với TLS, Kubernetes Services"

**Hiển thị kiến trúc:**
```bash
# Mở file kiến trúc
code docs/project_report.md
# Scroll đến phần "Kiến trúc hệ thống"
```

### **Phần 2: Kiểm Tra Trạng Thái Hiện Tại (2 phút)**

**Người thuyết trình nói:**
"Trước tiên, hãy kiểm tra trạng thái hiện tại của hệ thống. Chúng ta có 2 pods FastAPI và 1 pod PostgreSQL đang chạy."

**Lệnh demo:**
```bash
# 1. Kiểm tra pods
oc get pods

# Output expected:
# NAME                           READY   STATUS    RESTARTS   AGE
# fastapi-app-xxx-yyy            1/1     Running   0          10m
# fastapi-app-xxx-zzz            1/1     Running   0          10m
# postgresql-xxx                 1/1     Running   0          15m

# 2. Kiểm tra services và routes
oc get svc,route

# 3. Kiểm tra HPA
oc get hpa

# 4. Test endpoint
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/
```

### **Phần 3: Demo Scaling (3 phút)**

**Người thuyết trình nói:**
"Hệ thống sử dụng Horizontal Pod Autoscaler để tự động scale dựa trên CPU utilization. Hiện tại chúng ta có 2 pods. Hãy scale xuống 1 pod để demo manual scaling."

**Lệnh demo:**
```bash
# 1. Scale xuống 1 pod
oc scale deployment fastapi-app --replicas=1

# 2. Kiểm tra pods
oc get pods -l app=fastapi-app

# 3. Test endpoint vẫn hoạt động
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/

# 4. Scale lại lên 2 pods
oc scale deployment fastapi-app --replicas=2

# 5. Kiểm tra lại
oc get pods -l app=fastapi-app
```

### **Phần 4: Demo Stress Testing (5 phút)**

**Người thuyết trình nói:**
"Bây giờ chúng ta sẽ chạy stress test để đo hiệu năng của hệ thống. Script sẽ gửi 1000 requests với 20 concurrent connections."

**Lệnh demo:**
```bash
# 1. Mở script stress test
code scripts/final_stress_test.ps1

# 2. Chạy stress test
.\scripts\final_stress_test.ps1
```

**Giải thích kết quả:**
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

**Người thuyết trình nói:**
"Kết quả cho thấy:
- RPS: 7.85 requests/second với 2 pods
- Error Rate: 0% - hệ thống ổn định
- Latency: ~2s chủ yếu do network latency từ local đến OpenShift sandbox
- Hệ thống có thể xử lý concurrent load tốt"

### **Phần 5: Demo Health Checks và Monitoring (2 phút)**

**Người thuyết trình nói:**
"Ứng dụng có comprehensive health checks để đảm bảo reliability."

**Lệnh demo:**
```bash
# 1. Test các health endpoints
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/startup
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/live
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/ready

# 2. Kiểm tra logs
oc logs -l app=fastapi-app --tail=5
```

### **Phần 6: Demo Deployment Process (3 phút)**

**Người thuyết trình nói:**
"Hãy demo quá trình deployment từ đầu. Trước tiên, chúng ta sẽ xóa toàn bộ và deploy lại."

**Lệnh demo:**
```bash
# 1. Xóa tất cả resources
oc delete all --all
oc delete configmap,secret,pvc --all

# 2. Deploy database
oc apply -f kubernetes/db-configmap.yaml
oc apply -f kubernetes/secret.yaml
oc apply -f kubernetes/postgresql.yaml

# 3. Build application
oc start-build fastapi-app --from-dir=src --follow

# 4. Deploy application
oc apply -f kubernetes/deployment.yaml
oc apply -f kubernetes/configmap.yaml
oc apply -f kubernetes/log-configmap.yaml
oc apply -f kubernetes/service.yaml
oc apply -f kubernetes/route.yaml
oc apply -f kubernetes/hpa.yaml

# 5. Verify deployment
oc get pods
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/
```

### **Phần 7: Kết Luận (1 phút)**

**Người thuyết trình nói:**
"Tóm lại, dự án đã thành công triển khai Private Cloud với:
- ✅ Triển khai ổn định trên OpenShift
- ✅ Horizontal scaling với HPA
- ✅ Stress test với 0% error rate
- ✅ Tuân thủ đầy đủ 12 quy tắc phát triển

Cảm ơn quý thầy cô và các bạn đã theo dõi!"

## Lưu Ý Quan Trọng Cho Demo

### **Trước Demo:**
- Đảm bảo network ổn định
- Test tất cả commands trước
- Có backup plan nếu OpenShift lag

### **Trong Demo:**
- Giải thích từng bước chậm rãi
- Hiển thị output và giải thích ý nghĩa
- Chuẩn bị slide hoặc notes nếu cần

### **Xử Lý Sự Cố:**
- Nếu pod không start: `oc logs <pod-name>`
- Nếu curl fail: Kiểm tra route URL
- Nếu stress test chậm: Giải thích là do network latency

### **Thời Gian Phân Bổ:**
- Giới thiệu: 2 phút
- Kiểm tra trạng thái: 2 phút
- Scaling demo: 3 phút
- Stress test: 5 phút
- Health checks: 2 phút
- Deployment process: 3 phút
- Kết luận: 1 phút

**Tổng: ~18 phút**

## Commands Tóm Tắt (Copy-Paste Ready)

```bash
# Pre-demo checks
oc get pods
oc get svc,route
oc get hpa
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/

# Scaling demo
oc scale deployment fastapi-app --replicas=1
oc get pods -l app=fastapi-app
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/
oc scale deployment fastapi-app --replicas=2

# Stress test
.\scripts\final_stress_test.ps1

# Health checks
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/live
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/ready
curl.exe https://fastapi-route-crt-20521594-dev.apps.rm2.thpm.p1.openshiftapps.com/health/startup

# Full redeploy (if needed)
oc delete all --all; oc delete configmap,secret,pvc --all
oc apply -f kubernetes/db-configmap.yaml kubernetes/secret.yaml kubernetes/postgresql.yaml
oc start-build fastapi-app --from-dir=src --follow
oc apply -f kubernetes/deployment.yaml kubernetes/configmap.yaml kubernetes/log-configmap.yaml kubernetes/service.yaml kubernetes/route.yaml kubernetes/hpa.yaml
```