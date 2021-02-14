param (
    [string]$DeployInfoFile,
    [string]$ProfileName="default"
)
$Resource = Get-Content -Raw -Path $DeployInfoFile | ConvertFrom-Json

# 証明書を削除する
aws iot update-certificate --certificate-id $Resource.certificateId --new-status "INACTIVE" --profile $ProfileName
aws iot delete-certificate --certificate-id $Resource.certificateId --force-delete --profile $ProfileName

# ロールエイリアスを削除する
aws iot delete-role-alias --role-alias $Resource.roleAliasName --profile $ProfileName

# スタックを削除する
aws cloudformation delete-stack --stack-name $Resource.stackName --profile $ProfileName
