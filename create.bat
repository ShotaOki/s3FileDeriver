@ECHO OFF
SET S3_BUCKET_NAME=
SET S3_FILE_NAME=
SET PROFILE_NAME=
SET YAML_PATH="aws/cloudformation/s3-deliver.yaml"
SET EXPORT_FOLDER="outputs"

CLS
ECHO --------------------------
ECHO AWSリソースを作成します
ECHO --------------------------
ECHO.
ECHO --------------------------
ECHO デバイス証明書でダウンロードさせるS3のバケット名を入力してください
ECHO 　入力例： bucket-resource-20210101
ECHO.
SET /P S3_BUCKET_NAME="バケット名："
CLS
ECHO --------------------------
ECHO デバイス証明書でダウンロードさせるS3のファイル名を入力してください
ECHO 　入力例（バケット直下なら）： /filename.txt
ECHO 　入力例（フォルダの中なら）： /folderA/filename.txt
ECHO.
SET /P S3_FILE_NAME="ファイル名："
CLS
IF NOT "%S3_FILE_NAME:~0,1%" == "/" (
    ECHO --------------------------
    ECHO エラー：ファイル名は/から始まる文字列である必要があります
    ECHO --------------------------
    PAUSE
    EXIT /B
)
ECHO --------------------------
ECHO AWSのプロファイル名（.aws\configの環境名）を入力してください
ECHO 　もし環境名がないなら、defaultを入力してください
ECHO.
SET /P PROFILE_NAME="プロファイル名："
CLS
ECHO -------------------------
ECHO 入力した情報は以下の通りです、誤りがなければキーを押下してください
ECHO もし誤りがあれば閉じるを押してバッチを終了してください
ECHO.
ECHO バケット名：%S3_BUCKET_NAME%
ECHO ファイル名：%S3_FILE_NAME%
ECHO プロファイル名：%PROFILE_NAME%
ECHO -------------------------

ECHO.
PAUSE
ECHO.

REM リソースを作成する
powershell -NoProfile -ExecutionPolicy Unrestricted aws\script\init.ps1 -S3BucketName %S3_BUCKET_NAME% -S3FileName %S3_FILE_NAME% -YamlPath %YAML_PATH% -ExportFolder %EXPORT_FOLDER% -ProfileName %PROFILE_NAME%

ECHO 処理を終了しました
PAUSE
