param (
    [string]$DeployInfoFile,
    [string]$PfxFilePath
)

# リソースを読み込む
$Resource = Get-Content -Raw -Path $DeployInfoFile | ConvertFrom-Json

$Format = "-{0} `"{1}`""
$DirectFormat = "-{0} {1}"
$RequestData = @(
    [String]::Format("powershell -NoProfile -ExecutionPolicy Unrestricted {0}", ".\download_with_device_cert.ps1")
    [String]::Format($Format, "ApiHostUri", $Resource.endpointAddress),
    [String]::Format($Format, "RequestRoleName", $Resource.roleAliasName),
    [String]::Format($Format, "PfxFilePath", $PfxFilePath),
    [String]::Format($DirectFormat, "PfxPassword", "%PASSWORD%"),
    [String]::Format($Format, "DownloadBucketsName", $Resource.bucketEndpoint),
    [String]::Format($Format, "DownloadFilePath", $Resource.fileName),
    [String]::Format($Format, "ServiceRegion", $Resource.s3Region)
) -join " "

Write-Host $RequestData
