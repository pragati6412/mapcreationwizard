import os
import time
command="matlab -batch  \"analyze_hypsometric_integral('hello.tif');exit;\""
start =time.time()
os.system(command)
end=time.time()

print(end-start, "s")