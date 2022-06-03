import os
import sys
import json
from base64 import b64encode, b64decode
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad
from util import multi_accounts_task

KEY = (os.getenv('PASSWD') + '=' * 16)[0:16]


def encrypt(data: str, key: str):
    cipher = AES.new(key.encode('utf-8'), AES.MODE_CBC)
    ct_bytes = cipher.encrypt(pad(data.encode('utf-8'), AES.block_size))
    iv = b64encode(cipher.iv).decode('utf-8')
    ct = b64encode(ct_bytes).decode('utf-8')
    return b64encode(
        json.dumps({'iv': iv, 'ciphertext': ct})[::-1].encode('utf-8')
    ).decode('utf-8')


def decrypt(data: str, key: str):
    data = json.loads(b64decode(data)[::-1])
    iv = b64decode(data['iv'])
    ct = b64decode(data['ciphertext'])
    cipher = AES.new(key.encode('utf-8'), AES.MODE_CBC, iv)
    return unpad(cipher.decrypt(ct), AES.block_size).decode('utf-8')


def handle(path):
    with open(path, 'r') as f:
        origin = f.read()

    with open(path, 'w') as f:
        if sys.argv[1] == 'e':
            f.write(encrypt(origin, KEY))
            return '应用信息已加密'
        elif sys.argv[1] == 'd':
            f.write(decrypt(origin, KEY))
            return '应用信息已解密'


if __name__ == '__main__':
    if len(sys.argv) == 1:
        exit(1)

    multi_accounts_task(handle)
