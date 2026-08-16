#!/usr/bin/env python3
"""Decode, encode, or patch Samsung DRParser *_keystrings.dat files."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
from zipfile import ZipFile


BLOCK_SIZE = 64
PLAINTEXT_BLOCK_SIZE = 53
PUBLIC_EXPONENT = 65537


def read_private_numbers(apk: Path) -> tuple[int, int]:
    with ZipFile(apk) as archive:
        modulus = int.from_bytes(archive.read("assets/mod_pri_key.txt"), "big")
        private_exponent = int.from_bytes(
            archive.read("assets/exp_pri_key.txt"), "big"
        )
    return modulus, private_exponent


def decode_block(block: bytes, modulus: int, private_exponent: int) -> bytes:
    if len(block) != BLOCK_SIZE:
        raise ValueError(f"invalid encrypted block size: {len(block)}")
    encoded = pow(int.from_bytes(block, "big"), private_exponent, modulus)
    payload = encoded.to_bytes(BLOCK_SIZE, "big").lstrip(b"\x00")
    if not payload:
        raise ValueError("empty decoded RSA block")
    return payload


def decode_file(data: bytes, modulus: int, private_exponent: int) -> bytes:
    if len(data) % BLOCK_SIZE:
        raise ValueError("encrypted file is not aligned to 64-byte blocks")
    return b"".join(
        decode_block(data[offset : offset + BLOCK_SIZE], modulus, private_exponent)
        for offset in range(0, len(data), BLOCK_SIZE)
    )


def encode_file(data: bytes, modulus: int) -> bytes:
    encrypted = bytearray()
    for offset in range(0, len(data), PLAINTEXT_BLOCK_SIZE):
        block = data[offset : offset + PLAINTEXT_BLOCK_SIZE]
        message = int.from_bytes(block, "big")
        if message >= modulus:
            raise ValueError("plaintext RSA block exceeds the modulus")
        cipher = pow(message, PUBLIC_EXPONENT, modulus)
        encrypted.extend(cipher.to_bytes(BLOCK_SIZE, "big"))
    return bytes(encrypted)


def set_package(xml: bytes, sequence: str, package: str) -> bytes:
    escaped_sequence = re.escape(sequence.encode())
    pattern = re.compile(
        rb"(<keystring>\s*<keysequence>"
        + escaped_sequence
        + rb"</keysequence>.*?<packagename>)(.*?)(</packagename>)",
        re.DOTALL,
    )
    replacement = rb"\1" + package.encode() + rb"\3"
    patched, count = pattern.subn(replacement, xml)
    if count != 1:
        raise ValueError(f"expected one {sequence!r} entry, found {count}")
    return patched


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--encode", action="store_true")
    parser.add_argument("--set-package-for-sequence")
    parser.add_argument("--package")
    args = parser.parse_args()

    if bool(args.set_package_for_sequence) != bool(args.package):
        parser.error("--set-package-for-sequence and --package must be used together")
    if args.encode and args.set_package_for_sequence:
        parser.error("--encode cannot be combined with package patching")

    modulus, private_exponent = read_private_numbers(args.apk)
    source = args.input.read_bytes()
    if args.set_package_for_sequence:
        xml = decode_file(source, modulus, private_exponent)
        xml = set_package(xml, args.set_package_for_sequence, args.package)
        output = encode_file(xml, modulus)
        action = "patched"
    elif args.encode:
        output = encode_file(source, modulus)
        action = "encoded"
    else:
        output = decode_file(source, modulus, private_exponent)
        action = "decoded"

    args.output.write_bytes(output)
    print(f"{action} {len(output)} bytes to {args.output}")


if __name__ == "__main__":
    main()
