# skip over conan's line number

# remove leading 0s from index
s/ 0/ /g

# color
s/ g / 1 /g
s/ b / 2 /g
s/ p / 3 /g
s/ v / 4 /g

# relevant feature
s/ farbe / 1 /g
s/ linie / -1 /g

# congruency of cue/answer
s/ c / -1 /g
s/ i / 1 /g

# answer
s/ f / -1 /g
s/ j / 1 /g
