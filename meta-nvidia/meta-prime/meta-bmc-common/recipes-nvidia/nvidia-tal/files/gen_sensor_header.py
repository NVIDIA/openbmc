import csv
import os
import json
import sys

argc_num=len(sys.argv)
if  argc_num < 3:
    sys.exit("command format: ./gen_sensor_header src_file out_file")

snr_table=[]
with open(sys.argv[1], newline='') as in_file:
    reader = csv.reader(in_file, delimiter=',')
    next(reader)
    next(reader)
    next(reader)
    for row in reader:
        offset=row[0]
        length=row[1]
        file=os.path.basename(row[3])
        cell={'name': file, 'offset': offset, 'length': length}
        snr_table.append(cell);
        #print (cell);


def gen_header(out):
    with open(out, 'w+') as f:
        str="//automatically generated table\n"
        str+="std::map<uint16_t, uint8_t> sensorMap = {\n"
        for cell in snr_table:
            str+="    {"+cell["offset"]+" ,"+cell["length"]+"},";
            str+="//" + cell["name"]+"\n";
        str+="};\n"
        f.write(str)

gen_header(sys.argv[2])
