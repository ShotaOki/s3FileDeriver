import OpenSSL
import json
import re
from argparse import ArgumentParser
from pathlib import Path

# 引数を解析する
parser = ArgumentParser()
parser.add_argument(
    '--deploy-info', 
    dest='deploy_info', 
    required=True,
    help='デプロイ情報のあるファイルパスを設定します'
)
parser.add_argument(
    '--password', 
    dest='password', 
    required=True,
    help='パスワードを設定します'
)
parser.add_argument(
    '--prefix', 
    dest='prefix', 
    required=False,
    help='証明書のプレフィックスを設定します'
)
parser.add_argument(
    '--root-ca', 
    dest='ca', 
    required=True,
    help='CA証明書のファイルパスを設定します'
)
parser.add_argument(
    '--export', 
    dest='export', 
    required=True,
    help='出力先のファイルパスを設定します'
)

def main(arg: ArgumentParser):
    """
    処理のエントリポイント

    Parameters
    --------------
    arg : バッチ引数
    """

    # デプロイ情報を読み込む
    config_path = Path(arg.deploy_info)
    deploy_info = {}
    if config_path.exists():
        try:
            with open(str(config_path.absolute()), mode="r", encoding='utf-8') as fp:
                json_str_data = fp.read()
                deploy_info = json.loads(json_str_data)
        except:
            # Powershellで出力したファイルはutf-8-sig（BOM付きUTF8）になっているため、
            # 読み込めなければ再試行する
            with open(str(config_path.absolute()), mode="r", encoding='utf-8-sig') as fp:
                json_str_data = fp.read()
                deploy_info = json.loads(json_str_data)

    # プレフィックスを読み込む
    prefix = arg.prefix if arg.prefix else deploy_info["prefix"]
    if (prefix is None) or (len(prefix) == 0):
        print(f"プレフィックス情報がありません")
        return

    # ファイルパスを作成する
    certificate_path = Path(config_path).with_name(f"{prefix}-certificate.pem.crt")
    private_key_path = Path(config_path).with_name(f"{prefix}-private.pem.key")
    pfk_export_path = Path(arg.export)
    if not certificate_path.exists():
        print(f"指定されたフォルダに証明書がありません : {certificate_path}")
        return
    if not Path(arg.ca).exists():
        print(f"指定されたフォルダにCA証明書がありません : {arg.ca}")
        return
    if not private_key_path.exists():
        print(f"指定されたフォルダに秘密鍵がありません : {private_key_path}")
        return

    # ファイルからバイナリを読み込む
    with open(str(certificate_path.absolute()), mode="rb") as fp:
        certificate_buffer = fp.read()
    with open(arg.ca, mode="rb") as fp:
        root_ca_buffer = fp.read()
    with open(str(private_key_path.absolute()) , mode="rb") as fp:
        private_key_buffer = fp.read()

    # 証明書、秘密鍵、CAのバイナリを、それぞれインスタンスに変換する
    certificate = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, certificate_buffer)
    root_ca = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, root_ca_buffer)
    priv_key = OpenSSL.crypto.load_privatekey(OpenSSL.crypto.FILETYPE_PEM, private_key_buffer)

    # PKCSのインスタンスに、証明書、秘密鍵、CAのインスタンスを設定する
    pkcs = OpenSSL.crypto.PKCS12()
    pkcs.set_privatekey(priv_key)
    pkcs.set_certificate(certificate)
    pkcs.set_ca_certificates([root_ca])

    # 出力する
    pkcs.set_friendlyname(f"{prefix}".encode("utf-8"))
    with open(str(pfk_export_path.absolute()), mode="wb") as fp:
        fp.write(pkcs.export(arg.password.encode("utf-8")))

main(parser.parse_args())
