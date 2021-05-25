# insar

This package is for students who are getting started with InSAR data and SBAS processing with MintPy.

## Contents
    1. docker image containing the relevant software
    2. some basic scripts to link together

## Installation instructions
    1. Clone a copy of this repository (or just download it as a zip file and unzip it).
    2. (optional step) Register at `urs.earthdata.nasa.gov`. Copy your login details (username and password) and put them into the relevant locations in the file `netrc`.
    3. Register at `https://asf.alaska.edu/`. Copy your login details (username and password) and put them into the relevant locations in `asf.ini`.
    4. Install [docker](https://www.docker.com/)
    5. In docker, pull the image we need with `docker pull benjym/insar:0.1.1`. This will take a long time the first time you do it (10-15 mins?).
    6. Run that docker container as an image. Under `Optional Settings`, put the path to the local version of this folder in `Host path` and `/home/work/` in the `Container path`. This will open a terminal running linux that has all the necessary packages installed and ready to go.

## Running a MintPy job
    1. Request and download processed InSAR products using `hyp3_sdk` or via the [website](https://search.asf.alaska.edu/#/).
    2. Download the corresponding DEM used in processing by running `python download_DEM.py`.
    3. Paste HyP3 interferogram metadata file (e.g. S1BB_20170510T070618_20170522T070619_VVP012_INT80_G_ueF_FF85.txt) into the same directory as your DEM and give it the same name as your DEM (e.g. dem.txt)
    4. TODO: Clip DEM and all interferograms to the same area using hyp3lib/cutGeotiffs.py script.
    5. Move the data you want to analyse into the `interferograms` folder. This should contain:
        1. One folder per granule, with the foldername the same as the granule ID (i.e. once you have unzipped the file, just drag the folder here). In each of these folders should the clipped phase tif, the clipped corr tiff and the metadata txt file.
        2. One folder called `DEM`, with the DEM tif, the clipped DEM tif and a DEM metadata txt file.
        3. One folder called `mintpy` with a mintpy metadata txt file. There is a sample file called `default.txt` to get you started.
    6. Run MintPy with the command `smallbaselineApp.py /home/work/mintpy/default.txt`
