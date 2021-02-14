@ECHO OFF
SET S3_BUCKET_NAME=
SET S3_FILE_NAME=
SET PROFILE_NAME=
SET YAML_PATH="aws/cloudformation/s3-deliver.yaml"
SET EXPORT_FOLDER="outputs"

CLS
ECHO --------------------------
ECHO AWS���\�[�X���쐬���܂�
ECHO --------------------------
ECHO.
ECHO --------------------------
ECHO �f�o�C�X�ؖ����Ń_�E�����[�h������S3�̃o�P�b�g������͂��Ă�������
ECHO �@���͗�F bucket-resource-20210101
ECHO.
SET /P S3_BUCKET_NAME="�o�P�b�g���F"
CLS
ECHO --------------------------
ECHO �f�o�C�X�ؖ����Ń_�E�����[�h������S3�̃t�@�C��������͂��Ă�������
ECHO �@���͗�i�o�P�b�g�����Ȃ�j�F /filename.txt
ECHO �@���͗�i�t�H���_�̒��Ȃ�j�F /folderA/filename.txt
ECHO.
SET /P S3_FILE_NAME="�t�@�C�����F"
CLS
IF NOT "%S3_FILE_NAME:~0,1%" == "/" (
    ECHO --------------------------
    ECHO �G���[�F�t�@�C������/����n�܂镶����ł���K�v������܂�
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
ECHO ������肪����Ε���������ăo�b�`���I�����Ă�������
ECHO.
ECHO �o�P�b�g���F%S3_BUCKET_NAME%
ECHO �t�@�C�����F%S3_FILE_NAME%
ECHO �v���t�@�C�����F%PROFILE_NAME%
ECHO -------------------------

ECHO.
PAUSE
ECHO.

REM ���\�[�X���쐬����
powershell -NoProfile -ExecutionPolicy Unrestricted aws\script\init.ps1 -S3BucketName %S3_BUCKET_NAME% -S3FileName %S3_FILE_NAME% -YamlPath %YAML_PATH% -ExportFolder %EXPORT_FOLDER% -ProfileName %PROFILE_NAME%

ECHO �������I�����܂���
PAUSE
