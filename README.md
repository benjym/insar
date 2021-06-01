# insar

This package is for people who are processing SBAS InSAR data with MintPy from ASF Vertex. If these things mean nothing to you then this is probably not the best place to start.

## Contents
1. docker image containing the relevant software
2. some basic scripts to link together

## Installation instructions
1. Clone this repository (or just download it as a zip file and unzip it if cloning sounds too hard).
2. Copy the file `netrc.copy` and rename the new file `netrc`. Register at `urs.earthdata.nasa.gov` and put your login details (username and password) into the relevant locations in the file `netrc`.
3. Copy the file `asf.copy` and rename the new file `asf.ini`. Register at `https://asf.alaska.edu/`. Copy your login details (username and password) and put them into the relevant locations in `asf.ini`.
4. Install [docker](https://www.docker.com/) and have it running on your computer.
5. In docker, pull the image we need with `docker pull benjym/insar:latest`. This will take a long time the first time you do it (10-15 mins?).
6. Run that docker image as a container. Under `Optional Settings`, put the path to the local version of this folder in `Host path` and `/home/work/` in the `Container path`. This will open a terminal running linux that has all the necessary packages installed and ready to go.

## Running a MintPy job
1. Request and download processed InSAR products using `hyp3_sdk` or via the [ASF Vertex website](https://search.asf.alaska.edu/#/). Move the data you want to analyse into the `interferograms` folder. This folder should contain one folder per granule, with the foldername the same as the granule ID, i.e. once you have unzipped the file, just drag unzipped folder into the `interferograms` folder. You will need to create this folder if it doesn't exist.
2. Next we want to download the Digital Elevation Map (DEM) that corresponds to the data we are interested in. We have two options, 1: Download a pre-defined area base on its latitude and longitude or 2: Download the part of the DEM that corresponds to a specific Scene from ASF. Pick either of the below methods, they are pretty much equivalent:
    1. Open up the file `download_DEM.py` and edit the `lat_max`, `lat_min`, `lon_max`, `lon_min` to fit your area. You can then download the corresponding DEM used in processing by running `python download_DEM.py`.
    2. Go to [ASF Vertex](https://search.asf.alaska.edu/#/), do a Geographic search for one of the Scenes you are studying, and download that Scene by first adding it to your Download Queue, then clicking Downloads at the top right, and then clicking the cloud with a down arrow button next to the file. Unzip this file. Run the following command in the docker prompt: `python /home/python/miniconda3/lib/python3.8/site-packages/hyp3lib/get_dem.py FILENAME /home/work/DEM/dem.tif` where `FILENAME` is the path to the `.SAFE` folder within the unzipped folder.
3. Copy and paste the HyP3 interferogram metadata file (e.g. `S1BB_20170510T070618_20170522T070619_VVP012_INT80_G_ueF_FF85.txt`) into the same directory as your DEM and give it the same name as your DEM (e.g. `dem_clip.txt`)
4. Clip DEM and all interferograms to the same area by running `python trim.py`. NOTE: This will trim **every** possible file in all subfolders to the same area, so make sure only files you want are in this folder and subfolders.
5. Run MintPy with the command `smallbaselineApp.py mintpy/default.txt`
