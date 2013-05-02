netmap = {}

filelines = 9322699,9313367,7978191,9462077
infiles = 'DB1B_2010_Q1.csv','DB1B_2010_Q2.csv','DB1B_2010_Q3.csv','DB1B_2010_Q4.csv'
for iter in range(4):
  input = open(infiles[iter],'r')
  numlines = filelines[iter]
  for i in range(numlines):
    line = input.readline()
    orig, dest, peeps,newline = line.split(',')
    peeps = float(peeps)
    if orig in netmap:
      if dest in netmap.get(orig):
        netmap[orig][dest] = float(netmap[orig].get(dest)) + peeps
      else:
        netmap[orig][dest] = peeps
    else: 
      netmap[orig] = {}
      netmap[orig][dest] = peeps
  input.close() 
  print "Got through file " + str(iter)

output = open('netmap_2010.txt','w')
for i,j in netmap.items():
  i = i.strip('\"')
  output.write(i)
  output.write(': ')
  for m,p in j.items():
    m = m.strip('\"')
    output.write(m)
    output.write(' ')
    p = str(p)
    output.write(p)
    output.write(', ')
  output.write('\n')

output.close()

output = open('keys_2010.txt','w')
for i in netmap.iterkeys():
  output.write('\"')
  output.write(i)
  output.write('\"\n')
output.close()
