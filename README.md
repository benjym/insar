# insar

This package is for people who are processing SBAS InSAR data with MintPy from ASF Vertex. If these things mean nothing to you then this is probably not the best place to start.

## Contents
1. Docker image containing the relevant software
2. Some basic scripts to link everything together

## Installation instructions
1. Install [docker](https://www.docker.com/) and have it running on your computer.
2. In Docker, pull the image we need with the command `docker pull benjym/insar:latest`. This will take a long time the first time you do it (10-15 mins?). While this is running, do the following steps.
3. Clone this repository (or just download it as a zip file and unzip it if cloning sounds too hard).
4. In the `scripts` folder, duplicate the file `netrc.copy` and rename the new file `netrc`. Register at `urs.earthdata.nasa.gov` and put your login details (username and password) into the relevant locations in the file `netrc`.
5. In the `scripts` folder, duplicate the file `model.copy` and rename the new file `model.cfg`. [Create a new account on the CDS website](https://cds.climate.copernicus.eu/user/register) if you don't have a user account yet. After activating your account use your new account to log in. Your user name will be show in the top right corner. You can now enter your user profile by clicking on your user name. On the profile you’ll find your user id (UID) and your personal API Key. Add the UID and key to the `model.cfg` file. You  must then accept the license terms [here](https://cds.climate.copernicus.eu/cdsapp/#!/terms/licence-to-use-copernicus-products).
6. (Optional, currently not necessary) In the `scripts` folder, duplicate the file `asf.copy` and rename the new file `asf.ini`. Register at `https://asf.alaska.edu/`. Copy your login details (username and password) and put them into the relevant locations in `asf.ini`.
7. (Optional, currently not necessary) In the `scripts` folder, duplicate the file `ecmwf` and rename the new file `ecmwfapirc`. Register at `https://apps.ecmwf.int/registration/`. Copy your login details (email address and [this key](https://api.ecmwf.int/v1/key/)) and put them into the relevant locations in `ecmwfapirc`. After you have registered, you need to [sign the agreement](https://apps.ecmwf.int/datasets/licences/general/). Full instructions [here](http://earthdef.caltech.edu/projects/pyaps/wiki/Main#).
8. Once the Docker image from step 2 is finished downloading, run that docker image as a container. Under `Optional Settings`, put the path to the local version of this folder in `Host path` and `/home/work/` in the `Container path`. This will open a terminal running linux that has all the necessary packages installed and ready to go.
9. (Optional) If you would like to check if the `model.cfg` file is working, you can test if this is working by running `python test_ECMWF.py` which will try to download some files.

## Running a MintPy job
1. Request and download processed InSAR products using `hyp3_sdk` or via the [ASF Vertex website](https://search.asf.alaska.edu/#/). Full instructions are [here](https://docs.asf.alaska.edu/vertex/sbas/).

   **Note:** You need to enable the sliders for "Include DEM" and "Include Inc. Angle Map" before submitting the job.

   Once the data is processed, download it. Move the data you want to analyse into the `data/interferograms` folder. This folder should contain one folder per granule, with the foldername the same as the granule ID, i.e. once you have unzipped the file, just drag the unzipped folder into the `interferograms` folder.
2. Copy and paste one of the HyP3 dem files (e.g. `S1BB_20170510T070618_20170522T070619_VVP012_INT80_G_ueF_FF85_dem.tif`) into the `data/DEM` folder and rename it `dem.tif`
3. Copy and paste the HyP3 interferogram metadata file (e.g. `S1BB_20170510T070618_20170522T070619_VVP012_INT80_G_ueF_FF85.txt`) into the same directory as your DEM (`/home/work/data/DEM/`) and rename it `dem_clip.txt`
4. Clip the DEM and all interferograms to the same area by running `python trim.py`. NOTE: This will trim **every** possible file in all subfolders within `./data/` to the same area, so make sure only files you want are in this folder and subfolders.
5. Run MintPy with the command `smallbaselineApp.py data/mintpy/default.txt`
