# Private Cloud FastAPI Project

Dự án triển khai ứng dụng FastAPI trên Red Hat OpenShift với PostgreSQL và horizontal scaling.

## Cấu trúc thư mục

```
.
├── .s2i/                    # Source-to-Image configuration
├── docs/                    # Documentation
│   ├── project_report.md    # Báo cáo dự án
│   └── Đồ+Án+giữa+kỳ+môn+Cloud.txt
├── kubernetes/              # Kubernetes manifests
│   ├── configmap.yaml
│   ├── db-configmap.yaml
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── log-configmap.yaml
│   ├── pgbouncer-configmap.yaml
│   ├── pgbouncer-deployment.yaml
│   ├── pgbouncer-service.yaml
│   ├── pgo-subscription.yaml
│   ├── pipeline.yaml
│   ├── postgresql.yaml
│   ├── route.yaml
│   ├── secret.yaml
│   └── service.yaml
├── scripts/                 # Utility scripts
│   ├── final_stress_test.ps1
│   ├── pgo-subscription.yaml
│   ├── pipeline.yaml
│   ├── simple_test.ps1
│   └── stress_test.ps1
├── src/                     # Source code
│   ├── Dockerfile
│   ├── log_config.ini
│   ├── log_config.json
│   ├── main.py
│   └── requirements.txt
└── tests/                   # Test files (empty)
```

## Cách sử dụng

1. Triển khai: `oc apply -f kubernetes/`
2. Build: `oc new-build --strategy=source --image-stream=python:3.9 --name=fastapi-app .`
3. Stress test: `.\scripts\final_stress_test.ps1`

## Demo

- **Hướng dẫn demo chi tiết**: Xem `demo_guide.md`
- **Script demo tự động**: Chạy `.\demo_script.ps1` để demo tự động
- **Thời gian demo**: ~15-20 phút

## Yêu cầu

- OpenShift CLI (oc)
- PowerShell (cho stress test)
- Python 3.9+ (cho development)