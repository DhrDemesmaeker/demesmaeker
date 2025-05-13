#!/usr/bin/env bash
set -e

# directory where your .cl files live
KDIR=cl

echo "Patching all .cl files in $KDIR…"
for f in "$KDIR"/*.cl; do
  echo " → $f"

  # 1) memcpy helper: 
  #    from    static void memcpy(uchar *dest, uchar *src, size_t n)
  #    to      static void memcpy(__global uchar *dest, __global const uchar *src, size_t n)
  sed -i -E '
    s|static +void +memcpy\(uchar +\*dest, +uchar +\*src, +size_t +n\)|\
static void memcpy(__global uchar *dest, __global const uchar *src, size_t n)|g
  ' "$f"

  # 2) ripemd160_process:
  #    from    void ripemd160_process(RIPEMD160_CTX *ctx, const uint8_t data[64])
  #    to      void ripemd160_process(__global RIPEMD160_CTX *ctx, __global const uchar *data)
  sed -i -E '
    s|void +ripemd160_process\([^,]+, +const +uint8_t +data\[64\]\)|\
void ripemd160_process(__global RIPEMD160_CTX *ctx, __global const uchar *data)|g
  ' "$f"

  # — Repeat the same pattern for your other helpers —
  # e.g. sha256, sha512, hmac_sha512, secp256k1 helpers, etc:
  #    change all pointer args from plain uchar*/uint*/… to __global qualifiers.
  #
  # Example for sha256:
  sed -i -E '
    s|static +void +sha256\(__private +const +unsigned +int +\*pass, +int +pass_len, +__private +unsigned +int\* +hash\)|\
static void sha256(__global const unsigned int *pass, int pass_len, __global unsigned int *hash)|g
  ' "$f"

  # Example for a secp256k1 helper (adjust names as you have them):
  sed -i -E '
    s|void +secp256k1_ecpubkey_create\([^,]+, +const +unsigned char +\*seckey\)|\
void secp256k1_ecpubkey_create(__global secp256k1_pubkey *pubkey, __global const uchar *seckey)|g
  ' "$f"

done

echo "Done. Now recompile and those address-space mismatches should be gone."
