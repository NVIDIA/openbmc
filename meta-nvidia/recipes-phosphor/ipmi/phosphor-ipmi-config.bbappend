FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

inherit image_version
# Calculate the Firmware Revision and auxiliary revision using the dev_id.json
# file. It is calculated from the VERSION_ID.
# The version formats are:
#  <ID>-YY.MM-N[-rcN] - for release candidate
#  <ID>-YY.MM-N_br - for branch release
#  <ID>-YY.MM-N
# The YY is the major version and the MM is the minor version and will be represented in ipmitool mc info as:
# Firmware Revision         : YY.MM
# The aux field is 4 bytes, the first 3 bytes are:
# Auxiliary version[0]: ID – create according to dictionary
# Auxiliary version[1]: N (binary val - max possible value 255)
# Auxiliary version[2]: N(binary val - rcN - max 255)
# Auxiliary version[3]: Not in use
#  Each platform will have its ID range:
# 0x00 -> 0xF - Core
# 0x10 -> 0x1F - BF - BMC 
# 0x20 -> 0x2F - HMC
# 0x30 -> 0x3F - G+H family
# 0xFF - Not in dictionary
# For example BF3BMC-22.10-3-rc5
# Firmware Revision   : 22.10
# aux version:
#             0x10
#             0x03
#             0x05
#             0x00

python do_populate_version() {
        import json
        import re

        id_to_num = {'core': 0, 'bf': 16}
        version_name = do_get_version(d)
        is_in_format = re.findall("[a-zA-Z0-9]+[-](\d{1,2})[.](\d{1,2})[-](.*)", version_name)
        if not is_in_format:
            pass
        else:
            major_ver = re.findall("-(\d{1,2})\.", version_name)
            minor_ver = re.findall("\.(\d{1,2})-", version_name)
            # Conversion to BCD: For example 12 decimal, each number represented in 4 bits->  00010010 -> 18 in BCD
            minor_ver_bcd = int(minor_ver[0]) % 10 + int(int(minor_ver[0]) / 10) * 16;

            id = re.findall("(\A[a-zA-Z0-9]{1,})-", version_name)
            if id:
                id_num = id_to_num.get(id[0])  
            if not id or not id_num:
                id_num = 255
            count = re.findall("-(\d{1,2})", version_name)
            auxVer = id_num + (int(count[1]) << 8)
            rc_num = re.findall("-rc(\d{1,2})", version_name)     
            if rc_num:
                auxVer += int(rc_num[0]) << 16

            # Update dev_id.json with the information
            workdir = d.getVar('WORKDIR', True)
            file = os.path.join(workdir, 'dev_id.json')
            with open(file, "r+") as jsonFile:
                data = json.load(jsonFile)
                jsonFile.seek(0)
                jsonFile.truncate()
                if "firmware_revision" in data:
                    data["firmware_revision"]["major"] = int(major_ver[0])
                    data["firmware_revision"]["minor"] = int(minor_ver_bcd)
                data["aux"] = auxVer
                json.dump(data, jsonFile)
}
addtask populate_version after do_configure before do_compile