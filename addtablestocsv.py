import csv
import json
import sys

data = []
with open(sys.argv[1], "r") as f:
    data = list(csv.reader(f))

tmap = {}
with open("table_map.json", "r") as f:
    tmap = json.load(f)

d2 = []
for d in data[1:]:
    for t in tmap:
        if int(d[0]) in tmap[t]:
            d2.append([*d, t])

print(d2, len(data), len(d2))

with open("output-regs.csv", "w") as f:
    csv.writer(f).writerows(d2)
