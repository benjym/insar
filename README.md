# insar

This package is for people who are processing SBAS InSAR data with MintPy from ASF Vertex. If these things mean nothing to you then this is probably not the best place to start.

## Contents
1. Docker image containing the relevant software
2. Some basic scripts to link everything together

## Installation instructions
1. Install [docker](https://www.docker.com/) and have it running on your computer.
2. In Docker, pull the image we need with the command `docker pull benjym/insar:latest`. This will take a long time the first time you do it (10-15 mins?). While this is running, do the following steps.
3. Clone this repository (or just download it as a zip file and unzip it if cloning sounds too hard).
4. In the `logins` folder, duplicate the file `netrc.copy` and rename the new file `netrc`. Register at `urs.earthdata.nasa.gov` and put your login details (username and password) into the relevant locations in the file `netrc`.
5. In the `logins` folder, duplicate the file `model.copy` and rename the new file `model.cfg`. [Create a new account on the CDS website](https://cds.climate.copernicus.eu/user/register) if you don't have a user account yet. After activating your account use your new account to log in. Your user name will be show in the top right corner. You can now enter your user profile by clicking on your user name. On the profile you’ll find your user id (UID) and your personal API Key. Add the UID and key to the `model.cfg` file. You  must then accept the license terms [here](https://cds.climate.copernicus.eu/cdsapp/#!/terms/licence-to-use-copernicus-products).
6. (Optional, currently not necessary) In the `logins` folder, duplicate the file `asf.copy` and rename the new file `asf.ini`. Register at `https://asf.alaska.edu/`. Copy your login details (username and password) and put them into the relevant locations in `asf.ini`.
7. (Optional, currently not necessary) In the `logins` folder, duplicate the file `ecmwf` and rename the new file `ecmwfapirc`. Register at `https://apps.ecmwf.int/registration/`. Copy your login details (email address and [this key](https://api.ecmwf.int/v1/key/)) and put them into the relevant locations in `ecmwfapirc`. After you have registered, you need to [sign the agreement](https://apps.ecmwf.int/datasets/licences/general/). Full instructions [here](http://earthdef.caltech.edu/projects/pyaps/wiki/Main#).
8. Once the Docker image from step 2 is finished downloading, run that docker image as a container. Under `Optional Settings`, put the path to the local version of this folder in `Host path` and `/home/work/` in the `Container path`. Also put `8888` as the `Local Host`. This will open a terminal running linux that has all the necessary packages installed and ready to go.
9. (Optional) If you would like to check if the `model.cfg` file is working, you can test if this is working by running `python scripts/test_ECMWF.py` which will try to download some files.

## Running a MintPy job
1. Request and download processed InSAR products using `hyp3_sdk` or via the [ASF Vertex website](https://search.asf.alaska.edu/#/). Full instructions are [here](https://docs.asf.alaska.edu/vertex/sbas/).

   **Note:** You need to enable the sliders for "Include DEM" and "Include Inc. Angle Map" before submitting the job.

   Once the data is processed, download it. Move the data you want to analyse into the `/home/work/data/hyp3/` folder. This folder should contain one folder per granule, with the foldername the same as the granule ID, i.e. once you have unzipped the file, just drag the unzipped folder into the `interferograms` folder.
2. Clip the DEM and all interferograms to the same area by running `python scripts/trim.py`. NOTE: This will trim **every** relevant tif file in all subfolders within `/home/work/data/hyp3/` to the same area, so make sure only files you want are in this folder and subfolders.
3. Run MintPy with the command `smallbaselineApp.py data/mintpy/default.txt`
4. To view the timeseries data, run `./open_visualisations`. This will start a web server that you can open in your browser. In the command line it will print some lines, one of which will be similar to: `http://127.0.0.1:8888/lab?token=653782a1b156bb037fba6a30c3d345ae4f2ece536f01497b`. Copy and paste this link into your browser to access the visualisations. To use `tsview`, open this file, then in the second code block replace `~/work/FernandinaSenDT128/mintpy` with `/home/work/` and `timeseries_ECMWF_ramp_demErr.h5` with, for example `timeseries_ERA5.h5`.
