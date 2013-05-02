allkeys = open('keys.txt','r')
allcoords = open('Airport_Norm_Coords2.csv','r')
output = open('Airport_Norm_Coords_2010.csv','w')
keylist = []
spam = allkeys.read()
for x in spam.split('\n'):
  keylist.append(x)
for line in allcoords.readlines():
  code, lat, long = line.split()
  if code in keylist:
    output.write(code)
    output.write(' ')
    output.write(lat)
    output.write(' ')
    output.write(long)
    output.write('\n')
allkeys.close() 
allcoords.close()
output.close()
