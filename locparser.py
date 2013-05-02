input = open('Airport_Norm_Coords.csv','r')
output = open('Airport_Norm_Coords2.csv','w')
# 65 shrinks the real coords to fit in a 220x220 patch world
# originally lat 33.9167 and long 78.7794 were used to normalize
#   each dimension to 100 but its stupid to scale each dimension
#   by a different amount. the +x constant is to fit it also.
for line in input.readlines():
  code, lat, long = line.split()
  lat = 100 * float(lat) / 65
  long = (-100 * float(long) / 65) + 20
  long = str(long)
  lat = str(lat)
  output.write(code)
  output.write(' ')
  output.write(lat)
  output.write(' ')
  output.write(long)
  output.write('\n')
input.close() 
output.close()
