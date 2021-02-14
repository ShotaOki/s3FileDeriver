@ECHO OFF
SET DEPLOY_INFO_FILE=
SET PASSWORD=
SET PFX_FILE=certificate.pfx

ECHO --------------------------
ECHO 証明書をPKCS#12に変換します
ECHO --------------------------
ECHO.
ECHO --------------------------
ECHO 変換フォルダにある、deploy-info.jsonへのパスを指定してください
ECHO 　入力例： outputs\202101011234510\deploy-info.json
ECHO.
SET /P DEPLOY_INFO_FILE="デプロイ情報ファイル："
CLS
IF NOT "%DEPLOY_INFO_FILE:~-4%" == "json" (
    ECHO --------------------------
    ECHO エラー：ファイル名はJSON形式である必要があります
    ECHO --------------------------
    PAUSE
    EXIT /B
)
ECHO --------------------------
ECHO 証明書に設定するパスワードを入力してください
ECHO.
SET /P PASSWORD="パスワード："
CLS
ECHO -------------------------
ECHO 入力した情報は以下の通りです、誤りがなければキーを押下してください
ECHO 　もし誤りがあれば閉じるを押してバッチを終了してください
ECHO.
ECHO デプロイ情報ファイル：%DEPLOY_INFO_FILE%
ECHO パスワード　　　　　：%PASSWORD%
ECHO -------------------------

ECHO.
PAUSE
ECHO.

REM バッチファイルを作成する
MKDIR export
DEL /q export\*
COPY aws\resource\download_template.bat export\download.bat
powershell -NoProfile -ExecutionPolicy Unrestricted .\aws\script\show.ps1 -DeployInfoFile %DEPLOY_INFO_FILE% -PfxFilePath %PFX_FILE% >> export\download.bat

COPY powershell\download_with_device_cert.ps1 export\download_with_device_cert.ps1

REM リソースを作成する
python aws\script\pem_to_pfx.py --deploy-info %DEPLOY_INFO_FILE% --password %PASSWORD% --root-ca aws\resource\AmazonRootCA1.pem --export export\%PFX_FILE%

ECHO 変換を完了しました
PAUSE
