# 変数をバッチ引数から読み込む
param(
    [string]$ApiHostUri,
    [string]$RequestRoleName,
    [string]$PfxFilePath,
    [string]$PfxPassword,
    [string]$DownloadBucketsName,
    [string]$DownloadFilePath,
    [string]$ServiceRegion
)

# ------------------
# 定数定義
# ------------------

# HTTPのリクエストメソッド
$REQUEST_METHOD = "GET"
# 署名バージョン（v4）
$AWS_AUTH_VERSION_4 = "AWS4-HMAC-SHA256"
# 空文字に対するSHA-2
$EMPTY_SHAR256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
# RESTでリクエストするヘッダ（ここに指定したヘッダだけ送信できる）
$REQUEST_HEADERS = "host;x-amz-content-sha256;x-amz-date;x-amz-security-token"
# クエリ（S3へのGETはクエリがないため空文字）
$QUERY_STRING = ""
# 署名するサービス名
$SERVICE_S3 = "s3"
# S3エンドポイントのプロトコル
$S3_PROTOCOL = "https"
# 秘密鍵をHMACで署名する時のプレフィックス
$AWS_SECRET_KEY_PREFIX = "AWS4"
# スコープのポストフィックス
$SIGNATURE_KEY_POSTFIX = "aws4_request"
# IoTのエンドポイント
$ASSUME_ROLE_ENDPOINT_FORMAT = "https://{0}/role-aliases/{1}/credentials"
# 日時フォーマット：年月日時分秒
$AMAZON_UTC_DATE_TIME_FORMAT = "yyyyMMddTHHmmssZ"
# 日時フォーマット：年月日
$AMAZON_UTC_DATE_FORMAT = "yyyyMMdd"

# Securityライブラリの読み込み
Add-Type -AssemblyName System.Security

function BinaryToHex {
    # 引数のバイナリを16進数形式の文字列に変換する
    param(
        [byte[]]$Binary # 変換するバイナリ
        # Return : 16進数形式の文字列
    )
    # 小文字の16進数を返す
    $HexFormat = "x2"
    return ($Binary | ForEach-Object { $_.ToString($HexFormat) }) -join ''
}

function CreateSha256Hash {
    # 引数のテキストからSha256形式のハッシュを作成する
    param (
        [string]$Text # ハッシュ化するテキスト
        # Return : Sha256のハッシュ文字列
    )
    # SHAの作成インスタンスを取得する
    $ShaInstance = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
    # Byte型に変換する
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    # 16進数（小文字）のSha256に変換する
    $Result = BinaryToHex($ShaInstance.ComputeHash($Bytes))
    # インスタンスの破棄
    $ShaInstance.Dispose()
    return $Result
}

function CreateHmacEncriptedData {
    # 引数のテキストと鍵を使ってHMACで変換する
    param(
        [byte[]]$KeyBinary, # 鍵（バイナリ形式）
        [string]$Text # 変換するテキスト
        # Return : HMACのバイナリ
    )
    # HMACの作成インスタンスを取得する
    $HmacInstance = New-Object System.Security.Cryptography.HMACSHA256
    # 秘密鍵を設定
    $HmacInstance.key = $KeyBinary
    # 16進数（小文字）のHMACに変換する
    $Result = $HmacInstance.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))
    # インスタンスの破棄
    $HmacInstance.Dispose()
    return $Result
}

function GetSignatureKey {
    # AWS v4形式の署名キーを作成する
    param (
        [string]$SecretAccessKey, # 秘密鍵
        [string]$DateStamp, # YYYYMMDD形式のAPI実行日時
        [string]$Region, # リクエストするAWSのリージョン
        [string]$Service, # リクエストするAWSのサービス名
        [string]$Postfix, # スコープのポストフィックス
        [string]$SecretKeyPrefix # 秘密鍵のプレフィックス
        # Return : 署名キーのバイナリ
    )
    # 署名v4の基本情報（アクセスキーID、送信日時、リージョン、サービス名）をHMAC-SHA256でハッシュ化する
    $AwsSecretKey = [System.Text.Encoding]::UTF8.GetBytes([String]::Format("{0}{1}", $SecretKeyPrefix, $SecretAccessKey))
    $Tmp = CreateHmacEncriptedData -KeyBinary $AwsSecretKey -Text $DateStamp
    $Tmp = CreateHmacEncriptedData -KeyBinary $Tmp -Text $Region
    $Tmp = CreateHmacEncriptedData -KeyBinary $Tmp -Text $Service
    return CreateHmacEncriptedData -KeyBinary $Tmp -Text $Postfix
}

# TLS 1.2を利用する
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# .pfxを読み込む
$PfxCertificate = [System.IO.File]::ReadAllBytes($PfxFilePath)

# 証明書インスタンスを作成する (X509 with password)
$X509Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($PfxCertificate, $PfxPassword)

# Device証明書からAssume RoleするためのAPIエンドポイントを作成する
$AssumeRoleEndpointUri = [String]::Format($ASSUME_ROLE_ENDPOINT_FORMAT, $ApiHostUri, $RequestRoleName)

# Assume Roleする
$AccessInfo = Invoke-RestMethod -Method Get -Uri $AssumeRoleEndpointUri -Certificate $X509Certificate

# UTC日時を取得する（フォーマット例：2020/12/31T12:34:50のとき AMZ_DATE:20201231T123450Z DATE_STAMP:20201231）
$UtcDate = (get-date).ToUniversalTime()
$AmzDate = $UtcDate.ToString($AMAZON_UTC_DATE_TIME_FORMAT)
$DateStamp = $UtcDate.ToString($AMAZON_UTC_DATE_FORMAT)

# 正規リクエストにフォーマット変換する
# 参考情報：タスク 1: 署名バージョン 4 の正規リクエストを作成する
# https://docs.aws.amazon.com/ja_jp/general/latest/gr/sigv4-create-canonical-request.html
$CanonicalRequestDigest = CreateSha256Hash(@(
        $REQUEST_METHOD,
        $DownloadFilePath,
        $QUERY_STRING,
        (@(
                [String]::Format("host:{0}", $DownloadBucketsName),
                [String]::Format("x-amz-content-sha256:{0}", $EMPTY_SHAR256),
                [String]::Format("x-amz-date:{0}", $AmzDate),
                [String]::Format("x-amz-security-token:{0}", $AccessInfo.credentials.sessionToken),
                ""
            ) -join "`n"),
        $REQUEST_HEADERS,
        $EMPTY_SHAR256
    ) -join "`n")

# 署名文字列を作成する
# 参考情報：タスク 2: 署名バージョン 4 の署名文字列を作成する
# https://docs.aws.amazon.com/ja_jp/general/latest/gr/sigv4-create-string-to-sign.html
$SecurityScope = [String]::Format("{0}/{1}/{2}/{3}", $DateStamp, $ServiceRegion, $SERVICE_S3, $SIGNATURE_KEY_POSTFIX)
$AuthPayload = @(
    $AWS_AUTH_VERSION_4,
    $AmzDate,
    $SecurityScope,
    $CanonicalRequestDigest
) -join "`n"

# 署名のため、Signatureを計算する
# 参考情報：タスク 3: AWS署名バージョン 4 の署名を計算する
# https://docs.aws.amazon.com/ja_jp/general/latest/gr/sigv4-calculate-signature.html
$SignatureKey = GetSignatureKey -SecretAccessKey $AccessInfo.credentials.secretAccessKey -DateStamp $DateStamp -Region $ServiceRegion -Service $SERVICE_S3 -Postfix $SIGNATURE_KEY_POSTFIX -SecretKeyPrefix $AWS_SECRET_KEY_PREFIX
$Signature = BinaryToHex(CreateHmacEncriptedData -KeyBinary $SignatureKey -Text $AuthPayload)

# 署名をHTTPリクエストのヘッダに設定する
# 参考情報：タスク 4: HTTP リクエストに署名を追加する
# https://docs.aws.amazon.com/ja_jp/general/latest/gr/sigv4-add-signature-to-request.html
$InvokeUri = [String]::Format("{0}://{1}{2}", $S3_PROTOCOL, $DownloadBucketsName, $DownloadFilePath)
$OutputFileName = [System.IO.Path]::GetFileName($DownloadFilePath)
$InvokeHeaders = @{
    "Authorization"        = @(
        [String]::Format("{0} Credential={1}/{2}", $AWS_AUTH_VERSION_4, $AccessInfo.credentials.accessKeyId, $SecurityScope),
        [string]::Format("SignedHeaders={0}", $REQUEST_HEADERS),
        [string]::Format("Signature={0}", $Signature)
    ) -join ",";
    "x-amz-content-sha256" = $EMPTY_SHAR256;
    "x-amz-date"           = $AmzDate;
    "x-amz-security-token" = $AccessInfo.credentials.sessionToken;
}

# HTTPでS3にリクエストする
Invoke-WebRequest -Method $REQUEST_METHOD -Headers $InvokeHeaders -OutFile $OutputFileName -Uri $InvokeUri
