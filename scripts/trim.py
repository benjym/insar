import os
from hyp3lib.cutGeotiffs import cutFiles

files = [] # empty list to store file names in
filetypes = ['unw_phase','corr','dem','lv_theta','water_mask']

for root, dir, filelist in os.walk('/home/work/data/hyp3/'):
    for file in filelist:
        for f in filetypes:
            if f + '.tif' in file:
                fullpath = os.path.join(root, file) # Get the full path to the file
                files.append(fullpath)

# print(f'Going to trim these files:{files}')

cutFiles(files)
