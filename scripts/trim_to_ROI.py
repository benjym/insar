import os, sys
from hyp3lib import saa_func_lib as saa
import re
import os
import argparse
from osgeo import gdal
from hyp3lib.cutGeotiffs import getPixSize, getCorners, getOverlap
from tqdm import tqdm

# use values in metres (easting/northing)
centre_easting = 242680.0
centre_northing = 6268360.0
width = 20000.0
height = 20000.0
coords = [centre_easting  - width/2.,
          centre_northing + height/2.,
          centre_easting  + width/2.,
          centre_northing - height/2.] # region of interest to trim to

files = [] # empty list to store file names in
filetypes = ['unw_phase','corr','dem','lv_theta','water_mask']

for root, dir, filelist in os.walk('/home/work/data/hyp3/'):
    for file in filelist:
        for f in filetypes:
            if f + '.tif' in file:
                fullpath = os.path.join(root, file) # Get the full path to the file
                files.append(fullpath)

# print(f'Going to trim these files:{files}')
print(f'Going to trim {len(files)} files')

if len(files) == 1:
    sys.exit("Nothing to do!!!  Exiting...")

# Open first file, get projection and pixsize
dst1 = gdal.Open(files[0])
p1 = dst1.GetProjection()

# Find the largest pixel size of all scenes
pixSize = getPixSize(files[0])
for x in range(len(files) - 1):
    tmp = getPixSize(files[x + 1])
    pixSize = max(pixSize, tmp)

# Make sure that UTM projections match
ptr = p1.find("UTM zone ")
if ptr != -1:
    (zone1,hemi) = [t(s) for t,s in zip((int,str), re.search("(\d+)(.)",p1[ptr:]).groups())]
    for x in range(len(files)-1):
        file2 = files[x+1]

        # Open up file2, get projection
        dst2 = gdal.Open(file2)
        p2 = dst2.GetProjection()

        # Cut the UTM zone out of projection2
        ptr = p2.find("UTM zone ")
        zone2 = re.search("(\d+)",p2[ptr:]).groups()
        zone2 = int(zone2[0])

        if zone1 != zone2:
            print("Projections don't match... Reprojecting %s" % file2)
            if hemi == "N":
                proj = ('EPSG:326%02d' % int(zone1))
            else:
                proj = ('EPSG:327%02d' % int(zone1))
            print("    reprojecting post image")
            print("    proj is %s" % proj)
            name = file2.replace(".tif","_reproj.tif")
            gdal.Warp(name,file2,dstSRS=proj,xRes=pixSize,yRes=pixSize)
            files[x+1] = name

# Find the overlap between all scenes
valid = []
for x in tqdm(range(len(files))):
    overlap = getOverlap(coords,files[x])
    # print(overlap)
    diff1 = (overlap[2] - overlap[0]) / pixSize
    diff2 = (overlap[3] - overlap[1]) / pixSize * -1.0
    if x == 0:
        diff1_truth = diff1
        diff2_truth = diff2
        print("Found overlap size of {}x{}".format(int(diff1), int(diff2)))

    if diff1 == diff1_truth and diff2 == diff2_truth:
        valid.append(x)
    elif diff1 < 1 or diff2 < 1:
        print(f"WARNING: There was no overlap between scene and RoI in file {files[x]}")
    else:
        print(f"WARNING: There was partial overlap between scene and RoI in file {files[x]}")

# Check to make sure there was some overlap
# print("Clipping coordinates: {}".format(coords))
# Finally, clip all scenes to the overlap region at the largest pixel size
lst = list(coords)
tmp = lst[3]
lst[3] = lst[1]
lst[1] = tmp
coords = tuple(lst)
print("Pixsize : x = {} y = {}".format(pixSize,-1*pixSize))
print('Clipping files... ')
for x in tqdm(range (len(files))):
    if x in valid:
        file1 = files[x]
        file1_new = file1.replace('.tif','_clip.tif')
        # print("    clipping file {} to create file {}".format(file1, file1_new))
        gdal.Warp(file1_new,file1,outputBounds=coords,xRes=pixSize,yRes=-1*pixSize,creationOptions = ['COMPRESS=LZW'])
print('Done!')
