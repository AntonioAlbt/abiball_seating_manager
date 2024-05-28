import csv
import json

reglist = []
with open("registrations.csv", "r") as f:
    reglist = list(csv.reader(f, lineterminator="\n"))
tablelist = []
with open("tables.csv", "r") as f:
    tablelist = list(csv.reader(f, lineterminator="\n"))
tablemap = {}
with open("table_map.json", "r") as f:
    tablemap = json.load(f)

tabledatamap = {}
for tbl in tablelist[1:]:
    tabledatamap[tbl[0]] = [tbl[1]]

regmap = {}
for reg in reglist[1:]:
    regmap[int(reg[0])] = [reg[1], int(reg[5]) if reg[5] != "NULL" else None]

def reger_for_reg(reg):
    return regmap[reg[1]] if reg[1] else None

for table in sorted(list(tablemap), key=lambda v: int(v)):
    print("## Tisch", table, f"({len(tablemap[table])} von {tabledatamap[table][0]})")
    print()
    for gid in tablemap[table]:
        reger = reger_for_reg(regmap[gid])
        print("-", regmap[gid][0].strip())
        # print("- ", regmap[gid][0].strip(), f" (Gast von #{regmap[gid][1]})" if reger else f" #{gid}", sep="")
    print()
