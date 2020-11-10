#!/usr/bin/env python3

tr = {"TCK": "!", "TDI": "#", "TMS": "\"", "TDO": "$"}

time = 10

print("#{}".format(time))
print("0!")

time += 100

f = open("output.txt", "r")

for line in f:
    tms = line[0]
    tdi = line[1]

    time += 100
    print("#{}".format(time))
    print("0!")
    print(tms+"\"")
    print(tdi+"#")

    time += 100
    print("#{}".format(time))
    print("1!")
