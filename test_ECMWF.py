import os
import sys
import numpy as np
import matplotlib.pyplot as plt
import pyaps3 as pa

print('------------------------------------------------')
print('You are using PyAPS from %s'%pa.__file__)
print('------------------------------------------------')

print('Testing Download Methods')
print('Testing ECMWF Downloads')
pa.ECMWFdload(['20140526','20130426'],'12','./', model='ERA5', snwe=(25,35,125,135))

print('------------------------------------------------')
print('Downloads OK')
print('------------------------------------------------')
