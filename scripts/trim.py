import os
from hyp3lib.cutGeotiffs import cutFiles

files = [] # empty list to store file names in

for root, dir, filelist in os.walk('/home/work/data/hyp3/'):
    for file in filelist:
        # if 'unw_phase.tif' in file or 'corr.tif' in file or 'inc_map.tif' in file or 'dem.tif' in file:
        if file[-8:] == 'corr.tif' or file[-13:] == 'unw_phase.tif' or file[-11:] == 'inc_map.tif' or file[-7:] == 'dem.tif':
            fullpath = os.path.join(root, file) # Get the full path to the file
            files.append(fullpath)

# print(f'Going to trim these files:{files}')

cutFiles(files)
