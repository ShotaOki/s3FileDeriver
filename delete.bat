@ECHO OFF
SET DEPLOY_INFO_FILE=
SET PROFILE_NAME=

ECHO --------------------------
ECHO AWS���\�[�X���폜���܂�
ECHO --------------------------
ECHO.
ECHO --------------------------
ECHO �폜�������t�H���_�ɂ���Adeploy-info.json�ւ̃p�X���w�肵�Ă�������
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
ECHO AWS�̃v���t�@�C�����i.aws\config�̊����j����͂��Ă�������
ECHO �@�����������Ȃ��Ȃ�Adefault����͂��Ă�������
ECHO.
SET /P PROFILE_NAME="�v���t�@�C�����F"
CLS
ECHO -------------------------
ECHO ���͂������͈ȉ��̒ʂ�ł��A��肪�Ȃ���΃L�[���������Ă�������
ECHO �@������肪����Ε���������ăo�b�`���I�����Ă�������
ECHO.
ECHO �f�v���C���t�@�C���F%DEPLOY_INFO_FILE%
ECHO �v���t�@�C�����F%PROFILE_NAME%
ECHO -------------------------

ECHO.
PAUSE
ECHO.

REM ���\�[�X���쐬����
powershell -NoProfile -ExecutionPolicy Unrestricted aws\script\delete.ps1 -DeployInfoFile %DEPLOY_INFO_FILE% -ProfileName %PROFILE_NAME%

ECHO �N���E�h���\�[�X�̍폜���I�����܂���
ECHO �@�����G���[���Ȃ���΁A�L�[�������đ��s���Ă�������
ECHO.
SET PARENT=%DEPLOY_INFO_FILE:~0,-17%
ECHO -------------------------
ECHO ����PC��̃t�@�C�����폜���܂�
ECHO �@%PARENT%���폜���܂��A��낵���ł����H
ECHO -------------------------
PAUSE

DEL /q %PARENT%\*
RD %PARENT%
