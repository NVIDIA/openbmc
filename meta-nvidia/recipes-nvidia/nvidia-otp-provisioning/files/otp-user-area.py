#!/usr/bin/env python3

from argparse import ArgumentParser
from collections import OrderedDict


def parse_args():
    ap = ArgumentParser()

    ap.add_argument(
        "--config",
        help="YAML file containing user area values",
        default="example.yaml",
    )
    ap.add_argument(
        "--output",
        help="Output file for user area binary",
        default="user_area.bin",
    )
    ap.add_argument(
        "patches",
        help="Manually overwrite chosen variables",
        type=str,
        metavar="var=value",
        nargs="*",
    )

    return ap.parse_args()


def load_yaml(filename):
    conf = OrderedDict()
    with open(filename, "r") as f:
        contents = f.readlines()
        for line in contents:
            if ':' in line:
                key, value = line.split(':')
                key = key.strip()
                value = value.strip()
                if value.startswith("0x"):
                    conf[key] = int(value, 16)
                else:
                    conf[key] = value

    return conf


def patch(data, patches):
    for patch in patches:
        key, value = patch.split("=")

        if key in data:
            if value.startswith("0x"):
                data[key] = int(value, 16)
            else:
                data[key] = value
        else:
            raise Exception(f"Unknown key: {key}")


def save_bin(data, output):
    mapper = OrderedDict(
        data_format_ver=lambda x: x.to_bytes(1, "big"),
        model_id=lambda x: x.to_bytes(2, "big"),
        hsm_id=lambda x: x.to_bytes(1, "big"),
        model_data_ver=lambda x: x.to_bytes(1, "big"),
        ik_subca_id=lambda x: x.to_bytes(1, "big"),
        tls_subca_id=lambda x: x.to_bytes(1, "big"),
        reserved=lambda x: x.to_bytes(1, "big"),
        unique_dev_id=lambda x: x.to_bytes(8, "big"),
        global_key_mat=lambda x: bytes.fromhex(x),
        dev_id_pkey=lambda x: bytes.fromhex(x),
        ik_cert_sig=lambda x: bytes.fromhex(x),
        tls_pkey=lambda x: bytes.fromhex(x),
        tls_cert_sig=lambda x: bytes.fromhex(x),
    )

    lengths = dict(
        global_key_mat=64,
        dev_id_pkey=48,
        ik_cert_sig=96,
        tls_pkey=48,
        tls_cert_sig=96,
    )

    result = {}
    for key, func in mapper.items():
        assert key in data, f"Invalid key: {key}"

        result[key] = func(data[key])

    for key, length in lengths.items():
        assert (
            len(result[key]) == length
        ), f"Invalid length {length} for key {key}"

    with open(output, "wb") as f:
        # Make sure we are iterating keys in the correct order.
        for key in mapper:
            f.write(result[key])


def main():
    args = parse_args()

    data = load_yaml(args.config)
    patch(data, args.patches)
    save_bin(data, args.output)

    print(f"Success, output file: {args.output}")


if __name__ == "__main__":
    main()
