@ECHO OFF
SET DEPLOY_INFO_FILE=
SET PROFILE_NAME=

ECHO --------------------------
ECHO AWSリソースを削除します
ECHO --------------------------
ECHO.
ECHO --------------------------
ECHO 削除したいフォルダにある、deploy-info.jsonへのパスを指定してください
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
ECHO AWSのプロファイル名（.aws\configの環境名）を入力してください
ECHO 　もし環境名がないなら、defaultを入力してください
ECHO.
SET /P PROFILE_NAME="プロファイル名："
CLS
ECHO -------------------------
ECHO 入力した情報は以下の通りです、誤りがなければキーを押下してください
ECHO 　もし誤りがあれば閉じるを押してバッチを終了してください
ECHO.
ECHO デプロイ情報ファイル：%DEPLOY_INFO_FILE%
ECHO プロファイル名：%PROFILE_NAME%
ECHO -------------------------

ECHO.
PAUSE
ECHO.

REM リソースを作成する
powershell -NoProfile -ExecutionPolicy Unrestricted aws\script\delete.ps1 -DeployInfoFile %DEPLOY_INFO_FILE% -ProfileName %PROFILE_NAME%

ECHO クラウドリソースの削除を終了しました
ECHO 　もしエラーがなければ、キーを押して続行してください
ECHO.
SET PARENT=%DEPLOY_INFO_FILE:~0,-17%
ECHO -------------------------
ECHO このPC上のファイルを削除します
ECHO 　%PARENT%を削除します、よろしいですか？
ECHO -------------------------
PAUSE

DEL /q %PARENT%\*
RD %PARENT%
