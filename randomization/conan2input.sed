# skip over conan's line number

# remove leading 0s from index
s/ 0/ /g

# color
s/ b / blue /g
s/ g / green /g
s/ p / pink /g
s/ v / violet /g

# direction of hatching
s/ w / SENW /g
s/ e / SWNE /g

# relevant feature
s/ F / farbe /g
s/ L / linie /g

# congruency of cue/answer
s/ c / con /g
s/ i / incon /g

# answer
s/ f / left /g
s/ j / right /g
