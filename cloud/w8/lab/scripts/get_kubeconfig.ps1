# Đọc tham số đầu vào JSON từ Terraform qua Stdin
$jsonInput = [Console]::In.ReadLine() | ConvertFrom-Json
$ip = $jsonInput.ip
$keyPath = $jsonInput.key_path

# Nếu chưa có IP hoặc Key, trả về giá trị trống (tránh lỗi lúc plan khi hạ tầng chưa được dựng)
if ([string]::IsNullOrEmpty($ip) -or [string]::IsNullOrEmpty($keyPath)) {
    $output = @{
        ca   = ""
        cert = ""
        key  = ""
    }
    Write-Output (ConvertTo-Json $output -Compress)
    exit 0
}

# Tự động sửa quyền tệp tin private key trên Windows để ssh.exe không báo lỗi bảo mật (too open)
if (Test-Path $keyPath) {
    # Tắt tính năng kế thừa quyền (inheritance)
    icacls "`"$keyPath`"" /inheritance:r 2>&1 | Out-Null
    # Cấp toàn quyền cho User hiện tại đang chạy lệnh
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    icacls "`"$keyPath`"" /grant:r "${currentUser}:F" 2>&1 | Out-Null
}

# Cấu hình SSH kết nối lấy nội dung file kubeconfig
# Sử dụng StrictHostKeyChecking=no để không bị dừng hỏi xác nhận fingerprint
$sshArgs = @(
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-i", "`"$keyPath`"",
    "ubuntu@$ip",
    "cat /home/ubuntu/.kube/config"
)

# Chạy SSH và hứng kết quả
$rawKubeconfig = ssh $sshArgs 2>$null

# Nếu PowerShell trả về mảng chuỗi (array of lines), gộp lại thành một chuỗi duy nhất để regex hoạt động chính xác
if ($rawKubeconfig -is [array]) {
    $rawKubeconfig = $rawKubeconfig -join "`n"
}

# Kiểm tra nếu kết quả trống hoặc không lấy được file
if ([string]::IsNullOrEmpty($rawKubeconfig) -or $rawKubeconfig -match "No such file") {
    $output = @{
        ca   = ""
        cert = ""
        key  = ""
    }
    Write-Output (ConvertTo-Json $output -Compress)
    exit 0
}

# Sử dụng Regex để trích xuất 3 chuỗi base64 của chứng chỉ
$caMatch = [regex]::Match($rawKubeconfig, 'certificate-authority-data:\s*([A-Za-z0-9+/=]+)')
$certMatch = [regex]::Match($rawKubeconfig, 'client-certificate-data:\s*([A-Za-z0-9+/=]+)')
$keyMatch = [regex]::Match($rawKubeconfig, 'client-key-data:\s*([A-Za-z0-9+/=]+)')

$output = @{
    ca   = if ($caMatch.Success) { $caMatch.Groups[1].Value } else { "" }
    cert = if ($certMatch.Success) { $certMatch.Groups[1].Value } else { "" }
    key  = if ($keyMatch.Success) { $keyMatch.Groups[1].Value } else { "" }
}

# Trả về kết quả dạng JSON chuẩn cho Terraform
Write-Output (ConvertTo-Json $output -Compress)
