import argparse
import logging
import os
import shutil

from osgeo import gdal

from hyp3lib.get_dem import get_dem
from hyp3lib.execute import execute
from hyp3lib.getSubSwath import get_bounding_box_file
from hyp3lib.saa_func_lib import get_utm_proj

# Don't change these unless you know what you are doing
use_opentopo=False
in_utm=True
post=None
dem_name=None

# Change these to suit your needs - currently set to the greater sydney/wollongong area
lat_max = -33.0874
lat_min = -34.9762
lon_max = 151.7999
lon_min = 149.6343

# Location to store the DEM file
outfile = './DEM/dem.tif'

if use_opentopo:
    demtype = None
    url = f'http://opentopo.sdsc.edu/otr/getdem' \
          f'?demtype=SRTMGL1&west={lon_min}&south={lat_min}&east={lon_max}&north={lat_max}&outputFormat=GTiff'
    execute(f'wget -O {outfile} "{url}"')

    if in_utm:
        proj = get_utm_proj(lon_min, lon_max, lat_min, lat_max)
        tmpdem = 'tmpdem_getDemFile_utm.tif'
        gdal.Warp(tmpdem, outfile, dstSRS=proj, resampleAlg='cubic')
        shutil.move(tmpdem, outfile)
else:
    dem_type = 'utm' if in_utm else 'latlon'
    demtype = get_dem(
        lon_min, lat_min, lon_max, lat_max, outfile, post=post, dem_name=dem_name, dem_type=dem_type
    )
    if not os.path.isfile(outfile):
        logging.error(f'Unable to find output file {outfile}')

# return outfile, demtype
