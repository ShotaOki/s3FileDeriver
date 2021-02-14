param (
    [string]$S3BucketName,
    [string]$S3FileName,
    [string]$YamlPath,
    [string]$ExportFolder,
    [string]$ProfileName="default"
)

$Prefix=(get-date).ToUniversalTime().ToString("yyyyMMddHHmmss")
$ExportFolderPath=[String]::Format("{0}/{1}", $ExportFolder, $Prefix)
$CertificateFileName=[String]::Format("{0}/{1}/{2}-certificate.pem.crt", $ExportFolder, $Prefix, $Prefix)
$PrivateKeyFileName=[String]::Format("{0}/{1}/{2}-private.pem.key", $ExportFolder, $Prefix, $Prefix)
$EndpointFileName=[String]::Format("{0}/{1}/deploy-info.json", $ExportFolder, $Prefix)
$YamlResource=[String]::Format("file://{0}", $YamlPath)

function ParseJson {
    # Json文字列をオブジェクトにパースします
    param (
        [string]$Text # JSON文字列
    )
    # オブジェクトに変換して返す
    return [regex]::Replace($Text, "[ `r`n]", "") | ConvertFrom-Json
}

# リソース名を定義
$StackName=[String]::Format("stack-s3-deliver-{0}", $Prefix)
$DeviceCeriticatePolicyName = [String]::Format("device-cert-s3-deliver-{0}", $Prefix)
$RoleAliasName = [String]::Format("role-alias-s3-deliver-{0}", $Prefix)
$S3AccessRoleName = [String]::Format("s3-access-s3-deliver-{0}", $Prefix)

# ロール、アクセス権限を作成
$ParameterFormat = "ParameterKey={0},ParameterValue={1}"
$Parameter = @(
    [String]::Format($ParameterFormat, "DeviceCeriticatePolicyName", $DeviceCeriticatePolicyName),
    [String]::Format($ParameterFormat, "RoleAliasName", $RoleAliasName),
    [String]::Format($ParameterFormat, "S3AccessRoleName", $S3AccessRoleName),
    [String]::Format($ParameterFormat, "S3BucketName", $S3BucketName),
    [String]::Format($ParameterFormat, "S3FileName", $S3FileName)
)
aws cloudformation create-stack --stack-name $StackName --template-body $YamlResource --parameters $Parameter --capabilities "CAPABILITY_NAMED_IAM" --profile $ProfileName

# 作成の完了を待機
aws cloudformation wait stack-create-complete --stack-name $StackName --profile $ProfileName

# デバイス証明書を作成
New-Item $ExportFolderPath -itemType "Directory"
$CertificateInfo = ParseJson(aws iot create-keys-and-certificate --set-as-active --certificate-pem-outfile $CertificateFileName --private-key-outfile $PrivateKeyFileName --profile $ProfileName)

# 作成されたロール情報を参照
$S3AccessRoleInfo = ParseJson(aws iam get-role --role-name $S3AccessRoleName --profile $ProfileName)

# ロールエイリアスを作成
aws iot create-role-alias --role-alias $RoleAliasName --role-arn $S3AccessRoleInfo.Role.Arn --profile $ProfileName

# デバイス証明書にロールをアタッチ
aws iot attach-principal-policy --principal $CertificateInfo.certificateArn --policy-name $DeviceCeriticatePolicyName --profile $ProfileName

# AssumeRoleのエンドポイントを取得
$EndpointInfo = ParseJson(aws iot describe-endpoint --endpoint-type "iot:CredentialProvider" --profile $ProfileName)

$S3Info = ParseJson(aws s3api get-bucket-location --bucket $S3BucketName --profile $ProfileName)

@{
    "endpointAddress"=$EndpointInfo.endpointAddress;
    "certificateId"=$CertificateInfo.certificateId;
    "roleAliasName"=$RoleAliasName;
    "stackName"=$StackName;
    "bucketName"=$S3BucketName;
    "fileName"=$S3FileName;
    "prefix"=$Prefix;
    "bucketEndpoint"=[String]::Format("{0}.s3-{1}.amazonaws.com", $S3BucketName ,$S3Info.LocationConstraint);
    "s3Region"=$S3Info.LocationConstraint;
} | ConvertTo-Json | Out-File $EndpointFileName -Encoding "UTF8"
