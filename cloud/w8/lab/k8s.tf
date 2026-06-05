# ==========================================
# KHỞI TẠO TÀI NGUYÊN KUBERNETES TRONG CỤM
# ==========================================

resource "kubernetes_config_map" "web_content" {
  metadata {
    name = "web-content"
  }

  data = {
    "index.html" = <<EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>W8 Kubernetes Lab</title>
    <style>
        body {
            font-family: 'Outfit', sans-serif;
            background: linear-gradient(135deg, #0f172a, #1e1b4b);
            color: #f8fafc;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.05);
            backdrop-filter: blur(10px);
            padding: 3rem;
            border-radius: 16px;
            box-shadow: 0 4px 30px rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        h1 {
            color: #38bdf8;
            margin-bottom: 1rem;
        }
        p {
            font-size: 1.2rem;
            color: #94a3b8;
        }
        .badge {
            background: #0284c7;
            padding: 0.5rem 1rem;
            border-radius: 9999px;
            font-size: 0.9rem;
            color: #fff;
            display: inline-block;
            margin-top: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>W8 Kubernetes Lab Successful!</h1>
        <p>Ứng dụng web đang chạy thực tế bên trong cụm Kubernetes Kind trên máy ảo AWS EC2.</p>
        <p>Được định tuyến an toàn thông qua Application Load Balancer (ALB).</p>
        <div class="badge">Học viên: Nguyễn Đức Chinh - XB-DN26-080</div>
    </div>
</body>
</html>
EOF
  }
}

resource "kubernetes_deployment" "web_app" {
  metadata {
    name   = "web-app"
    labels = {
      app = "web"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "web"
      }
    }

    template {
      metadata {
        labels = {
          app = "web"
        }
        annotations = {
          "configmap/checksum" = sha256(jsonencode(kubernetes_config_map.web_content.data))
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "html-volume"
            mount_path = "/usr/share/nginx/html"
          }
        }

        volume {
          name = "html-volume"
          config_map {
            name = kubernetes_config_map.web_content.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "web_app_service" {
  metadata {
    name = "web-app-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.web_app.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
      node_port   = 30080
    }

    type = "NodePort"
  }
}
