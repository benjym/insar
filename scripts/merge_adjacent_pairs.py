import numpy as np
import matplotlib.pyplot as plt
import os, glob
from osgeo import gdal
from shutil import copyfile

# Example filename
# S1AA_20190407T083915_20190419T083916_VVP012_INT80_G_ueF_3BAC_dem.tif
# S1xy-aaaaaaaaTbbbbbb_ggggggggThhhhhh_pponnn_INTzz_u_def_ssss
# x:          Sentinel-1 Mission (A or B) of reference granule
# y:          Sentinel-1 Mission (A or B) of secondary granule
# aaaaaaaa:   Start Date of Acquisition (YYYYMMDD) of reference granule
# bbbbbb:     Start Time of Acquisition (HHMMSS) of reference granule
# gggggggg:   Start Date of Acquisition (YYYYMMDD) of secondary granule
# hhhhhh:     Start Time of Acquisition (HHMMSS) of secondary granule
# pp:         Polarization Type: Vertical (VV) or Horizontal (HH)
# o:          Orbit Type: Precise (P), Restituted (R), or Original Predicted (O)
# nnn:        Time separation in days between reference and secondary granules
# zz:         Pixel Spacing in meters
# u:          Software Package Used: GAMMA (G)
# d:          Unmasked (u) or Water Masked (w)
# e:          Entire Area (e) or Clipped Area (c)
# f:          Swath Number: 1, 2, 3, or Full (F)
# ssss:       Product ID

# files = []
# for root, dir, filelist in os.walk('/home/work/data/hyp3/'):
#     for file in filelist:
#         # if 'unw_phase.tif' in file or 'corr.tif' in file or 'inc_map.tif' in file or 'dem.tif' in file:
#         if file[-8:] == 'corr.tif' or file[-13:] == 'unw_phase.tif' or file[-11:] == 'inc_map.tif' or file[-7:] == 'dem.tif':
#             fullpath = os.path.join(root, file) # Get the full path to the file
#             files.append(fullpath)
root_dir = '/home/work/data/hyp3-raw/'
out_dir = '/home/work/data/hyp3/'
merge_files = ['_unw_phase.tif', '_corr.tif', '_lv_theta.tif', '_water_mask.tif', '_dem.tif']

if not os.path.exists(out_dir): os.mkdir(out_dir)
folders = glob.glob(root_dir + '*/')
folders.sort()
prev_two_date_string = ''
prev_foldername = ''

for folder in folders[:3]:
    foldername = folder[len(root_dir):]
    date_a = foldername[5:13]
    date_b = foldername[21:29]
    two_date_string = date_a+date_b
    if two_date_string == prev_two_date_string:
        for f in merge_files:
            if not os.path.exists(out_dir + foldername): os.mkdir(out_dir + foldername)

            file_a = glob.glob(root_dir + prev_foldername + prev_foldername[:-1] + '*' + f)[0]
            file_b = glob.glob(root_dir + foldername + foldername[:-1] + '*' + f)[0]
            print(file_a,file_b)
            command = "gdal_merge.py -o " + out_dir + foldername + f + " -of gtiff " + file_a + file_b
            print(os.popen(command).read())

            copyfile(root_dir + foldername + foldername[:-1] + ".txt", out_dir + foldername + foldername[:-1] + ".txt")

    prev_two_date_string = two_date_string
    prev_foldername = foldername
command = "gdal_merge.py -o /Users/olearyd/Git/data/TEAK_Aspect_Tiles/TEAK_Aspect_Mosaic.tif -of gtiff " + files_string
print(os.popen(command).read())
