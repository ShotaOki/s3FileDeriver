@ECHO OFF
SET DEPLOY_INFO_FILE=
SET PASSWORD=
SET PFX_FILE=certificate.pfx

ECHO --------------------------
ECHO �ؖ�����PKCS#12�ɕϊ����܂�
ECHO --------------------------
ECHO.
ECHO --------------------------
ECHO �ϊ��t�H���_�ɂ���Adeploy-info.json�ւ̃p�X���w�肵�Ă�������
ECHO �@���͗�F outputs\202101011234510\deploy-info.json
ECHO.
SET /P DEPLOY_INFO_FILE="�f�v���C���t�@�C���F"
CLS
IF NOT "%DEPLOY_INFO_FILE:~-4%" == "json" (
    ECHO --------------------------
    ECHO �G���[�F�t�@�C������JSON�`���ł���K�v������܂�
    ECHO --------------------------
    PAUSE
    EXIT /B
)
ECHO --------------------------
ECHO �ؖ����ɐݒ肷��p�X���[�h����͂��Ă�������
ECHO.
SET /P PASSWORD="�p�X���[�h�F"
CLS
ECHO -------------------------
ECHO ���͂������͈ȉ��̒ʂ�ł��A��肪�Ȃ���΃L�[���������Ă�������
ECHO �@������肪����Ε���������ăo�b�`���I�����Ă�������
ECHO.
ECHO �f�v���C���t�@�C���F%DEPLOY_INFO_FILE%
ECHO �p�X���[�h�@�@�@�@�@�F%PASSWORD%
ECHO -------------------------

ECHO.
PAUSE
ECHO.

REM �o�b�`�t�@�C�����쐬����
MKDIR export
DEL /q export\*
COPY aws\resource\download_template.bat export\download.bat
powershell -NoProfile -ExecutionPolicy Unrestricted .\aws\script\show.ps1 -DeployInfoFile %DEPLOY_INFO_FILE% -PfxFilePath %PFX_FILE% >> export\download.bat

COPY powershell\download_with_device_cert.ps1 export\download_with_device_cert.ps1

REM ���\�[�X���쐬����
python aws\script\pem_to_pfx.py --deploy-info %DEPLOY_INFO_FILE% --password %PASSWORD% --root-ca aws\resource\AmazonRootCA1.pem --export export\%PFX_FILE%

ECHO �ϊ����������܂���
PAUSE
