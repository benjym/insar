import os
from hyp3lib.cutGeotiffs import cutFiles

files = [] # empty list to store file names in

for root, dir, filelist in os.walk('./data/'):
    for file in filelist:
        if file == 'dem.tif' or 'unw_phase.tif' in file or 'corr.tif' in file or 'inc_map.tif' in file:
            fullpath = os.path.join(root, file) # Get the full path to the file
            files.append(fullpath)

# print(f'Going to trim these files:{files}')

cutFiles(files)
