# skip over conan's line number
# replace the relevant feature (farbe & orient) before the color (g,b,p,o) and
# answer (f & j)

# remove leading 0s from index
s/ 0/ /g

# relevant feature
s/ farbe / 1 /g
s/ orient / 2 /g

# color
s/g/1/g
s/b/2/g
s/p/3/g
s/o/4/g

# congruency of cue/answer
s/c/1/g
s/i/2/g

# answer
s/f/1/g
s/j/2/g
s/d/3/g
s/k/4/g
