# from wthai@nvidia.com
# require: paramiko


import argparse
import logging
import subprocess
import time
from typing import Sequence
import random
import string
import paramiko
from contextlib import closing
import stat
import os
import numpy as np
import filecmp

emmc_test_dir = "/run/initramfs/emmc_test/"
emmc_test_script = emmc_test_dir + "emmc_test_script.sh"


def _parse_arguments(argv=None):
    # argument handler
    parser = argparse.ArgumentParser(
        description="""
        A simple script to stress the tester by various method of reboots.
        """
    )
    parser.add_argument("--log",
        help="the filename of log file",
        default="",)
    parser.add_argument(
        "--bmc_ip",
        help="force_bmc_ip",
        default="",
    )
    parser.add_argument(
        "--bmc_username",
        help="bmc user for ssh",
        default="sysadmin",
    )
    parser.add_argument(
        "--bmc_password",
        help="bmc user for ssh",
        default="superuser",
    )
    parser.add_argument(
        "--test",
        help="test command",
        choices=["euda","firmware","file_system","secure_erase","display_partition",
                    "mount","modify_partition", "error_handling", "emmc_write", "emmc_read",
                    "secure_support", "secure_erase", "stress", "emmc_corrupt_fs"],
        required=True
    )
    parser.add_argument(
        "--data",
        help="test data",
    )
    parser.add_argument(
        "--start",
        help="start of data to erase",
    )
    parser.add_argument(
        "--size",
        help="read data size",
    )
    parser.add_argument(
        "--task",
        help="sub task for test case",
        choices=["delete","format"]
    )
    parser.add_argument(
        "--nested_bmc",
        help="the network protocol contains nested controller or not",

        required=True
    )
    return parser.parse_args()

def _cmd(ssh: paramiko.SSHClient, cmd: str) -> str:
    #print("_cmd: ", cmd)
    stdin, stdout, stderr = ssh.exec_command(cmd)
    return stdout.read().decode()

def _reboot_bmc(bmc_ip: str, bmc_username: str, bmc_password: str
):
    logging.info("Power control with bmc ...")
    with paramiko.SSHClient() as bmc_ssh:
        bmc_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        bmc_ssh.connect(
            bmc_ip,
            username=bmc_username,
            password=bmc_password,
            banner_timeout=60
        )
        logging.info("reboot bmc...")
        bmc_ssh.exec_command(
            "reboot"
        )

def _power_cycle(
    bmc_ssh
):
    logging.info("Power cycle...")
    bmc_ssh.exec_command(
        "killall timeoutd 2>/dev/null;" # kill timeoutd
        "ipmitool chassis power cycle||ipmitool chassis power cycle -H 127.0.0.1 -U admin -P admin"
    )
    time.sleep(10)
    for i in range(0, 10):
        output = _cmd(bmc_ssh, "ipmitool chassis power status||ipmitool chassis power status -H 127.0.0.1 -U admin -P admin")
        logging.info(f"Power status after power cycle: [{output}]")
        if 'Chassis Power is on' in output:
            return True
        else:
            _cmd(bmc_ssh, "ipmitool chassis power on||ipmitool chassis power on -H 127.0.0.1 -U admin -P admin")
        time.sleep(10);

    return False            

def _power_status(
    bmc_ip: str, bmc_username: str, bmc_password: str
):
    with paramiko.SSHClient() as bmc_ssh:
        bmc_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        bmc_ssh.connect(
            bmc_ip,
            username=bmc_username,
            password=bmc_password,
            banner_timeout=60
        )
        logging.info("Power status...")

        output = _cmd(bmc_ssh, "ipmitool chassis power status||ipmitool chassis power status -H 127.0.0.1 -U admin -P admin")
        if 'Chassis Power is on' in output:
            return "on"
        elif 'Chassis Power is off' in output:
            return "off"
        else:
            logging.info("Power check failed...")
            return "fail"

def _check_connection(host: str, port: int = 22):
    logging.info(f"checking connection with {host}")
    i = 20;
    while subprocess.call(f"nc -vz {host} {port}".split()) != 0 and i != 0:
        time.sleep(30)
        i = i - 1
    if(i == 0):
        logging.info("Check connection failed.")
        return False
    logging.info("Check connection ok.")
    return True

def _upload_file_to_hmc(
    local_file: str, remote_path: str, hmc_ssh
):
    logging.info("Upload test script to HMC.")
    mode = stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR | stat.S_IRGRP | stat.S_IXGRP | stat.S_IXOTH
    sftp = hmc_ssh.open_sftp()
    remote_file = os.path.join(remote_path, local_file)

    logging.info("Uploading %s to %s.", local_file, remote_file)
    sftp.put(
        local_file,
        remote_file,
        callback=lambda done, remaining: None,
    )
    sftp.chmod(remote_file, mode)

def _download_file_from_hmc(remote_path, local_path, hmc_ssh):
    sftp = hmc_ssh.open_sftp()
    logging.info("Downloading %s from %s.", local_path, remote_path)
    sftp.get(
        remote_path,
        local_path,
        callback=lambda done, remaining: None,
    )

def get_bmc_ssh_client(
    bmc_ip: str, bmc_username: str, bmc_password: str
):
    #create bmc ssh client
    bmc_ssh = paramiko.SSHClient()
    bmc_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    bmc_ssh.connect(
        bmc_ip,
        username=bmc_username,
        password=bmc_password,
        banner_timeout=60
    )
    return bmc_ssh
def get_hmc_ssh_client(
    bmc_ssh, bmc_ip: str
):
    #create hmc ssh client
    vmtransport = bmc_ssh.get_transport()
    dest_addr = ('192.168.31.1', 22)
    local_addr = (bmc_ip, 22)
    vmchannel = vmtransport.open_channel("direct-tcpip", dest_addr, local_addr)
    
    #create hmc ssh client
    hmc_ssh = paramiko.SSHClient()
    hmc_ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    hmc_ssh.connect(
        '192.168.31.1',
        username='root',
        password='0penBmc',
        banner_timeout=60,
        sock=vmchannel
    )
    return hmc_ssh


def main(argv=None):
    args = _parse_arguments(argv)
    logging.basicConfig(
        filename=args.log,
        level=logging.INFO,
        format="[%(asctime)s] %(levelname)s %(lineno)d %(message)s",
    )
    if(args.nested_bmc == "True"):
        #create bmc ssh client
        bmc_ssh = get_bmc_ssh_client(args.bmc_ip, args.bmc_username, args.bmc_password)
        #check usb1
        output = _cmd(bmc_ssh, "ifconfig usb1")

        if output.find("addr:") == -1:
            #dc cycle
            logging.info("Usb1 absent, do dc cycle")
            rc = _power_cycle(bmc_ssh);
            if rc:
                logging.info("Power cycle ok.")
            else:
                logging.info("Power cycle failed.")
                return
            #reboot bmc
            _cmd(bmc_ssh, "reboot")
            _cmd(bmc_ssh, "reboot")
            if _check_connection(args.bmc_ip) ==  False:
                logging.info("Bmc lost after reboot.")
                return
            bmc_ssh = get_bmc_ssh_client(args.bmc_ip, args.bmc_username, args.bmc_password)
        
        hmc_ssh = get_hmc_ssh_client(bmc_ssh, args.bmc_ip)
    else:
        hmc_ssh = get_bmc_ssh_client(args.bmc_ip, args.bmc_username, args.bmc_password)
    #_cmd("cat /etc/os-release", args.bmc_ip, args.bmc_username, args.bmc_password)
    #upload test script to hmc
    _cmd(hmc_ssh, "mkdir " + emmc_test_dir)
    _upload_file_to_hmc("./emmc_test_script.sh", emmc_test_dir, hmc_ssh)

    #get emmc block devie
    command = f"{emmc_test_script} get_emmc_blk_devive"
    emmc_blk_device = _cmd(hmc_ssh, command)

    if args.test == "euda":
        command = f"{emmc_test_script} get_edua_size {emmc_blk_device}"
        output = _cmd(hmc_ssh, command)
        log_str = f"EUDA size: {output}"
        logging.info(log_str)
        print(log_str)
    elif args.test == "firmware":
        command = f"{emmc_test_script} get_fw_version {emmc_blk_device}"
        output = _cmd(hmc_ssh, command)
        log_str = f"Firmware: {output}"
        logging.info(log_str)
        print(log_str)
    elif args.test == "emmc_write":
        if args.data is None:
            print("Require --data option !!")
            return
        command = f"{emmc_test_script} emmc_write_all_partition {emmc_blk_device} {args.data}"
        output = _cmd(hmc_ssh, command)
        logging.info(f"{output}")
        print(f"{output}")
    elif args.test == "emmc_corrupt_fs":
        # Repeatedly write a long string to the partition and forcibly reboot
        command = f"{emmc_test_script} emmc_reboot_while_write {emmc_blk_device} 3"
        logging.info("Start writing to emmc.")
        print("Start writing to emmc.")
        output = _cmd(hmc_ssh, command)
        logging.info("Run power cycle.")
        print("Run power cycle.")
        # Reconnect to HMC
        for i in range(10):
            logging.info(f"Try reconnecting to HMC: #{i}")
            print(f"Try reconnecting to HMC: #{i}")
            try:
                hmc_ssh = get_hmc_ssh_client(bmc_ssh, args.bmc_ip)
                break
            # except paramiko.ssh_exception.ChannelException:
            except:
                logging.info(f"Fail to reconnecting to HMC: #{i}")
                print(f"Fail to reconnecting to HMC: #{i}")
                time.sleep(15);
        logging.info("Reconnect to HMC.")
        print("Reconnect to HMC.")
        # Check partition sanity
        command = f"mount | grep emmc"
        output = _cmd(hmc_ssh, command)
        logging.info(f"Show partitions:\n{output}")
        print(f"Show partitions:\n{output}")
        command = f"journalctl | grep emmc"
        output = _cmd(hmc_ssh, command)
        logging.info(f"Show journal:\n{output}")
    elif args.test == "emmc_read":
        if args.size is None:
            print("Require --size option !!")
            return
        command = f"{emmc_test_script} emmc_read_all_partition {emmc_blk_device} {args.size}"
        output = _cmd(hmc_ssh, command)
        logging.info(f"{output}")
        print(f"{output}")
    elif args.test == "secure_support":
        command = f"{emmc_test_script} get_secure_support {emmc_blk_device}"
        output = _cmd(hmc_ssh, command)
        logging.info(f"{output}")
        print(f"{output}")
    elif args.test == "secure_erase":
        if args.size is None or args.start is None:
            print("Require --start and --size !!")
            return
        command = f"{emmc_test_script} secure_erase {emmc_blk_device} {args.start} {args.size}"
        output = _cmd(hmc_ssh, command)
        logging.info(f"{output}")
        print(f"{output}")
    elif args.test == "display_partition":
        command = f"{emmc_test_script} get_partition {emmc_blk_device}"
        output = _cmd(hmc_ssh, command)
        logging.info(f"{output}")
        print(f"{output}")
    elif args.test == "mount":
        command = f"{emmc_test_script} get_mountpoint {emmc_blk_device}"
        output = _cmd(hmc_ssh, command)
        logging.info(f"{output}")
        print(f"{output}")
    elif args.test == "modify_partition":
        if args.task is None:
            return
        if args.task == "delete":
            if args.data is None:
                print("Require --data option !!")
                return 
            command = f"{emmc_test_script} delete_partition {args.data}"
        elif args.task == "format":
            if args.data is None:
                print("Require --data option !!")
                return 
            command = f"{emmc_test_script} format_partitions {args.data}"
        output = _cmd(hmc_ssh, command)
        logging.info(f"{output}")
        print(f"{output}")
    elif args.test == "file_system":
        command = f"{emmc_test_script} get_mountpoint {emmc_blk_device}"
        output = _cmd(hmc_ssh, command)
        for o in output.splitlines(): #test each mount point
            new_dir = ''.join(random.sample(string.ascii_uppercase*6, 12))
            new_file = ''.join(random.sample(string.ascii_uppercase*6, 12))
            new_content = ''.join(random.sample(string.digits*6, 12))
            #create dir
            _cmd(hmc_ssh, f"mkdir {o}/{new_dir}")
            #create file
            create_file = f"{o}/{new_dir}/{new_file}"
            _cmd(hmc_ssh, f"echo {new_content} > {create_file}")
            #check file create success
            output = _cmd(hmc_ssh, f"ls {create_file}")
            if output.rstrip('\n') != create_file:
                log_str = f"Create file in {o} failed."
            else:
                log_str = f"Create file in {o} ok."
            logging.info(log_str)
            print(log_str)
            #check file content
            output = _cmd(hmc_ssh, f"cat {create_file}")
            if output.rstrip('\n') != new_content:
                log_str = f"Check file content in {o} failed."
            else:
                log_str = f"Check file content in {o} ok."
            logging.info(log_str)
            print(log_str)
            #delete dir
            _cmd(hmc_ssh, f"rm -rf {o}/{new_dir}")
    elif args.test == "stress":
        command = f"{emmc_test_script} get_mountpoint {emmc_blk_device}"
        mounts = _cmd(hmc_ssh, command)
        logging.info("Stress Test File System.")
        #create 100MB file
        with open("random.dat","wb") as output: 
            output.write(np.random.bytes(5000000))

        for i in range(int(args.data)):
            logging.info(f"========={i}=========")
            for o in mounts.splitlines(): #test each mount point
                new_dir = ''.join(random.sample(string.ascii_uppercase*6, 12))
                new_file = ''.join(random.sample(string.ascii_uppercase*6, 12))
                new_content = ''.join(random.sample(string.digits*1024, 1024))
                #create dir
                _cmd(hmc_ssh, f"mkdir {o}/{new_dir}")
                #create file
                create_file = f"{o}/{new_dir}/{new_file}"
                _cmd(hmc_ssh, f"echo {new_content} > {create_file}")
                #check file create success
                output = _cmd(hmc_ssh, f"ls {create_file}")
                if output.rstrip('\n') != create_file:
                    log_str = f"Create file in {o} failed."
                else:
                    log_str = f"Create file in {o} ok."
                logging.info(log_str)
                print(log_str)
                #check file content
                output = _cmd(hmc_ssh, f"cat {create_file}")
                if output.rstrip('\n') != new_content:
                    log_str = f"Check file content in {o} failed."
                else:
                    log_str = f"Check file content in {o} ok."
                logging.info(log_str)
                print(log_str)
                #delete dir
                _cmd(hmc_ssh, f"rm -rf {o}/{new_dir}")
                #test upload/download file
                _upload_file_to_hmc("random.dat", f"{o}/", hmc_ssh)
                _download_file_from_hmc(f"{o}/random.dat", "download_random.dat", hmc_ssh)
                #compare two file
                if filecmp.cmp('random.dat', 'download_random.dat') == True:
                    log_str = f"Check upload/download file in {o} ok."
                else:
                    log_str = f"Check upload/download file in {o} fail."
                logging.info(log_str)
                os.remove("download_random.dat")
                _cmd(hmc_ssh, f"rm {o}/random.dat")
        os.remove("random.dat")
        logging.info("Stress Test Finish.")
    elif args.test == "error_handling":
        if args.data is None:
            print("Require --data option !!")
            return 
        command = f"{emmc_test_script} corrupt_fs {args.data}"
        output = _cmd(hmc_ssh, command)
        log_str = f"Corrupt partition {args.data} by dd command, let handling this error by running partition again or reboot."
        logging.info(log_str)
        print(log_str)
            
    #remove test script
    _cmd(hmc_ssh, "rm -rf " + emmc_test_dir)

if __name__ == "__main__":
    main()
