# skip over conan's line number

# remove leading 0s from index
s/ 0/ /g

# color
s/ b / 2 /g
s/ g / 1 /g
s/ p / 3 /g
s/ v / 4 /g

# direction of hatching
s/ w / SENW /g
s/ e / SWNE /g

# relevant feature
s/ F / 1 /g
s/ L / -1 /g

# congruency of cue/answer
s/ c / -1 /g
s/ i / 1 /g

# answer
s/ f / -1 /g
s/ j / 1 /g

# block type to frequency of incongruent trials and frequency of color trials
# incongruent trials: neutral=50, linie=50, farbe=50, incon=75, con=25
# color trials: neutral=50, linie=25, farbe=75, incon=50, con=50
s/ neutral / neutral 50 50 /g
s/ linie / linie 50 25 /g
s/ farbe / farbe 50 75 /g
s/ incongruent / incongruent 75 50 /g
s/ congruent / congruent 25 50 /g
