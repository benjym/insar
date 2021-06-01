import os
from hyp3lib.cutGeotiffs import cutFiles

files = [] # empty list to store file names in

for root, dir, filelist in os.walk('./'):
    for file in filelist:
        if file == 'dem.tif' or '_unw_phase.tif' in file or '_corr.tif' in file:
            fullpath = os.path.join(root, file) # Get the full path to the file
            files.append(fullpath)

# print(f'Going to trim these files:{files}')

cutFiles(files)
