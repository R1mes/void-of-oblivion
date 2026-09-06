#!/usr/bin/env python3
"""
Скрипт генерации цифровой подписи (RSA-2048 PKCS#1 v1.5 + SHA-256)
и манифеста обновлений version_manifest.json для 'Void of Oblivion'.

Использование:
    python3 sign_patch.py <path_to_pck_file> <patch_version> [changelog_text] [download_url]
"""
import os
import sys
import json
import hashlib
import base64
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
PRIV_KEY_PATH = os.path.join(PROJECT_ROOT, "security", "patch_private_key.key")

def sha256_file(filepath: str) -> tuple[bytes, str]:
    hasher = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.digest(), hasher.hexdigest()

def sign_hash_openssl(data_hash: bytes, priv_key_path: str) -> bytes:
    # OpenSSL dgst to sign SHA-256 hash
    cmd = [
        "openssl", "pkeyutl", "-sign",
        "-inkey", priv_key_path,
        "-pkeyopt", "digest:sha256"
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate(input=data_hash)
    if proc.returncode != 0:
        raise RuntimeError(f"OpenSSL sign failed: {stderr.decode('utf-8')}")
    return stdout

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 sign_patch.py <patch.pck> <version> [changelog] [download_url]")
        sys.exit(1)

    pck_path = os.path.abspath(sys.argv[1])
    version = sys.argv[2]
    changelog = sys.argv[3] if len(sys.argv) > 3 else f"Обновление {version}"
    download_url = sys.argv[4] if len(sys.argv) > 4 else f"https://github.com/R1mes/void-of-oblivion/releases/download/v{version}/{os.path.basename(pck_path)}"

    if not os.path.exists(pck_path):
        print(f"Error: PCK file not found at {pck_path}")
        sys.exit(1)

    if not os.path.exists(PRIV_KEY_PATH):
        print(f"Error: Private key not found at {PRIV_KEY_PATH}")
        sys.exit(1)

    file_size = os.path.getsize(pck_path)
    hash_bytes, hash_hex = sha256_file(pck_path)
    signature_bytes = sign_hash_openssl(hash_bytes, PRIV_KEY_PATH)
    signature_b64 = base64.b64encode(signature_bytes).decode("ascii")

    # Save standalone .sig file
    sig_path = pck_path + ".sig"
    with open(sig_path, "wb") as f:
        f.write(signature_bytes)

    # Optional mandatory flag
    is_mandatory = True
    if len(sys.argv) > 5:
        is_mandatory = sys.argv[5].lower() in ("true", "1", "yes")

    manifest = {
        "latest_version": version,
        "mandatory": is_mandatory,
        "changelog": changelog,
        "patch": {
            "version": version,
            "filename": os.path.basename(pck_path),
            "download_url": download_url,
            "size_bytes": file_size,
            "sha256": hash_hex,
            "signature_base64": signature_b64
        }
    }

    manifest_path = os.path.join(os.path.dirname(pck_path), "version_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print("==================================================")
    print(f"[SUCCESS] Patch signed successfully!")
    print(f"PCK File:    {pck_path} ({file_size} bytes)")
    print(f"SHA-256:     {hash_hex}")
    print(f"Signature:   {sig_path} ({len(signature_bytes)} bytes)")
    print(f"Manifest:    {manifest_path}")
    print("==================================================")

if __name__ == "__main__":
    main()
