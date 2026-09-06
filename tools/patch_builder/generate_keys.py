#!/usr/bin/env python3
import os
import subprocess

sec_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "security"))
os.makedirs(sec_dir, exist_ok=True)
priv_path = os.path.join(sec_dir, "patch_private_key.key")
pub_path = os.path.join(sec_dir, "patch_public_key.crt")

if not (os.path.exists(priv_path) and os.path.exists(pub_path)):
    subprocess.run(["openssl", "genpkey", "-algorithm", "RSA", "-out", priv_path, "-pkeyopt", "rsa_keygen_bits:2048"], check=True)
    subprocess.run(["openssl", "req", "-x509", "-key", priv_path, "-out", pub_path, "-days", "3650", "-subj", "/CN=VoidOfOblivionPatchKey"], check=True)
    print("Generated keys successfully!")
else:
    print(f"Keys exist already in {sec_dir}.")
