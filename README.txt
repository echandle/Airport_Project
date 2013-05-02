1) Look into airport.py
 a) Check infiles, output, and output
  i)   infiles:
        These are the raw data from the DOT DB1B survey formatted
          one row per transaction, three columns per row: 
          origin, destination, # tickets.
        To use files from a different time period:
          Edit the tuple infiles. Edit the cooresponding entry in filelines.
          (Filelines = number of lines in the file)
          Edit line 5 so iter goes through the proper # of files.
  ii)  output
        This is the network map formatted as:
          "orig": "dest1" #flights1, "dest2" #flights2,
          "orig2": "dest3" #flights3, "dest4" #flights4,
        Don't change anything here! Netlogo is set up to parse it.
  iii) output
        This file contains all the origin airports. Don't change anything here!
        Only the union of these airports and the airports from the coordinates
          file are passed to the Netlogo program. i.e. Only airports w/ traffic.

2) Look into trimcoords.py
 a) Check allkeys, output
  i)  allkeys
       This file should be the same output as output #2 above.
       Refer to 1.a.iii
  ii) output 
       Holds the coords of the airports we're using. Gets passed to Netlogo
         setup-airports procedure.
