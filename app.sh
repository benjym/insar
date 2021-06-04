DEM_FILE=/home/work/data/DEM/dem.tif
DEM_CLIP_FILE=/home/work/data/DEM/dem_clip.tif

if test -f "$DEM_FILE"; then
    echo "$DEM_FILE exists. Not re-downloading it. Remove this file and change the limits in downlod_DEM.py if you want to download a different DEM area."
else
    python /home/work/download_DEM.py
fi

if test -f "$DEM_CLIP_FILE"; then
    echo "$DEM_CLIP_FILE exists. Not re-running tif clipping. Remove this file if you want to clip everything again."
else
    python /home/work/trim.py
fi

smallbaselineApp.py /home/work/data/mintpy/default.txt
