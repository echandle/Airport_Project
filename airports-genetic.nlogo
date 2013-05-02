;To do: 1) Figure out how to kill small airports or small links and let everything still work cuz this simulation is ridiculous.
;          a) I think you can just do-netowrk anal, kill, do netowrk anal again. Since you ahe to do netowrk anal befor eyou kill, 
;              and killing changes the anal results
;       2) Figure out how to spawn and kill fishes and let them get where they want to be and see how well the network is serving them.


breed [ banners banner]
breed [ airports airport]
breed [ peeps peep]
breed [genes gene]


globals [ airport-name airport-size airport-x airport-y
          total-val max-flow char-dist node-num gen-winner 
        ]

airports-own[ name delay idegree odegree iflights oflights
              netdist visited prev]
links-own [bwth]
peeps-own [location disp-path]
genes-own [bits fitness]

to setup
  clear-all
  resize-world -110 110 -60 60
  set-patch-size 4
  set char-dist 12 ; 12 patches ~ 560 miles ~ airspeed of a 747
  ;import-drawing "map1.png"
  load-airport-data
  setup-airports
  setup-network
  do-network-anal
  kill-some
  do-network-anal
  set node-num count airports
  reset-ticks
end

;; This procedure loads in patch data from a file.  The format of the file is:
;; name x y size.
to load-airport-data

  ;; We check to make sure the file exists first
  ifelse ( file-exists? "Airport_Norm_Coords_2010.csv" )
  [
    ;; We are saving the data into a list, so it only needs to be loaded once.
    set airport-name []
    set airport-y []
    set airport-x []

    ;; This opens the file, so we can use it.
    file-open "Airport_Norm_Coords_2010.csv"

    ;; Read in all the data in the file
    while [ not file-at-end? ]
    [
      ;; file-read gives you variables. store columns into separate lists
      set airport-name sentence airport-name file-read
      set airport-y sentence airport-y file-read
      set airport-x sentence airport-x file-read
    ]

    show "File loading complete!"

    ;; Done reading in patch information.  Close the file.
    file-close
  ]
  [ user-message "There is no airport file in current directory!" ]
end

to setup-airports
  set-default-shape airports "target"
  show-airport-data
  ask banners [reposition]
end
    
to show-airport-data
  cp
  ifelse ( is-list? airport-name )
    [ let iter n-values 434 [?]
      foreach iter [ create-airports 1 [ 
                             set name item ? airport-name
                             set xcor item ? airport-x 
                             set ycor item ? airport-y
                             set size 2
                             set color 125
                             ;attach-banner name
                             ]]
      show "Done setting x,y"
    ]
    [ user-message "You need to load in airport data first!" ]
end

to attach-banner [x] 
  hatch-banners 1 [
    set size 2
    set label x
    create-link-from myself [
      tie
      hide-link
    ]
  ]
end

to reposition
  move-to one-of in-link-neighbors
  set heading 90
  fd .35
end
  
 
to setup-network
  file-open "netmap_2010.txt"
  let orig []
  let dest []
  let flights []
  let oneline []
  let pair []
  ; read in whole file eventually
  while [not file-at-end?]
  [
    set oneline file-read-line
    let linechars []
    ; store one line as list of chars
    while [not empty? oneline]
    [
      set linechars lput (first oneline) linechars
      set oneline but-first oneline
    ]
    set linechars remove " " linechars
    ; extract origin
    repeat 3[
      set orig lput (first linechars) orig
      set linechars but-first linechars
    ]
    set orig reduce word orig
    set linechars but-first linechars ; remove colon
    ; extract destination and flights
    while [not empty? linechars]
    [
      ifelse first linechars != "," 
      [
        set pair lput (first linechars) pair
        set linechars but-first linechars
      ]
      [
        repeat 3[
          set dest lput (first pair) dest
          set pair but-first pair
        ]
        set dest reduce word dest
        while [not empty? pair]
        [
          set flights lput (first pair) flights
          set pair but-first pair
        ]
        set flights reduce word flights
        set linechars but-first linechars
        ask airports [if name = orig [
            if orig != dest[
              create-links-to airports with [name = dest][
              set bwth read-from-string flights
              set color scale-color green log read-from-string flights 10 -1 5]
            ]]]
        set dest []
        set flights[]
      ]
    ]
    set orig []
    set oneline []
    set pair []
  ]
  file-close
  show "Flight network drawed."
end   

to do-network-anal
  get-degrees
  show "Network diagnostatized."
end

to get-degrees
  ask airports [
    set idegree count my-in-links
    set odegree count my-out-links
    set iflights sum [bwth] of my-in-links
    set oflights sum [bwth] of my-out-links
  ]
end

to kill-some
  ask airports [if iflights < 100000 [die]]
  show "Small airports removed."
end

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to setup-peeps
  set-default-shape peeps "fish"
  create-peeps 10[ 
    set color orange
    set size 3
    set location pick-outtarget
    ;move-to location
  ]
  show "Fishes in place."
end

to move-peeps
  ask peeps[
    set disp-path []
    let new-location pick-intarget
    set disp-path shortest-path new-location
;    if disp-path != nobody
;      [let iter n-values length disp-path [?]
;       foreach iter
;         [move-to item ? disp-path]
;       set location new-location
;      ]
  ]
  tick
end
  
to-report pick-outtarget
  let pick random-float sum [oflights] of airports
  let winner nobody
  ask airports [
    if winner = nobody[
      ifelse oflights > pick
      [ set winner self]
      [ set pick pick - oflights ]
    ]
  ]
  report winner
end

to-report pick-intarget
  let pick random-float sum [iflights] of airports
  let winner nobody
  ask airports [
    if winner = nobody[
      ifelse iflights > pick
      [ set winner self]
      [ set pick pick - iflights ]
    ]
  ]
  report winner
end

to-report shortest-path [target]
  let dt dijkstra-weight target
  ;show "Path length: " 
  ;show dt
  ifelse (dt < 9999999) 
  [
    let temp target
    let path []
    let infloop 0
    while [temp != location][
      set path fput [prev] of temp path
      set temp [prev] of temp
      set infloop infloop + 1
      if infloop > 9000 [show "infinite loop" report nobody]
    ]
    report path
  ]
  [ report nobody]
end

to-report dijkstra [target]
  ask airports [
    set netdist 9999
    set visited false
    set prev nobody
  ]
  let unseen sort airports
  set unseen remove self unseen
  let temp self
  ask temp [set netdist 0]
  let uneigh []
  while [[visited] of target = false][
    foreach unseen [if member? ? sort [out-link-neighbors] of temp [
      set uneigh lput ? uneigh]
    ]
    foreach uneigh [ask ? [if netdist > 1 + [netdist] of temp [
      set netdist 1 + [netdist] of temp
      set prev temp]]]
    ask temp [set visited true]
    set unseen remove temp unseen
    if [visited] of target = true [report [netdist] of target]
    set unseen sort-by [[netdist] of ?1 < [netdist] of ?2] unseen
    set temp first unseen
  ]
 report 999
end

to-report dijkstra-weight [target]
  ask airports [
    set netdist 999999999
    set visited false
    set prev nobody
  ]
  let unseen sort airports
  set unseen remove self unseen
  let temp location
  ask temp [set netdist 0]
  let uneigh []
  while [[visited] of target = false][
    foreach unseen [if member? ? sort [out-link-neighbors] of temp [
      set uneigh lput ? uneigh]
    ]
    foreach uneigh [ask ? [if netdist > distance temp + [netdist] of temp [
      set netdist distance temp + [netdist] of temp
      set prev temp]]]
    ask temp [set visited true]
    set unseen remove temp unseen
    if [visited] of target = true [report [netdist] of target]
    set unseen sort-by [[netdist] of ?1 < [netdist] of ?2] unseen
    set temp first unseen
  ]
 report 9999999
end

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to setup-genetic
  create-genes population-size [
    set bits n-values (node-num * node-num) [one-of [0 1]]
    set hidden? true  ;; the genes' locations are not used, so hide them
  ]
  foreach sort genes [calculate-fitness ?]
  tick
end

to go-genetic
  create-next-generation
  ;update-display
  tick
end


;; ===== Generating Solutions

;; Each solution has its "fitness score" calculated.
;; Lower scores mean "more fit", and higher scores mean "less fit".
;; The lower a fitness score, the more likely that this solution
;;   will be chosen to reproduce and create offspring solutions
;;   in the next generation.
;;
to calculate-fitness [x]     ;; gene procedure
  ask x [set fitness 0
  parse-bits bits
  ]
  repeat 10[
    setup-peeps
    move-peeps
    ask x[set fitness peep-get-fitness fitness]
    ask peeps[die]
  ]
  
  ask x[
    let total-length 0
    foreach sort airports [
      let n1 ?
      foreach sort airports [
        let n2 ?
        if n1 != n2 [
          ask n1 [ set total-length total-length + distance n2]
        ]
      ]
    ]
  set fitness fitness + 100 * (count links) + 10000 * total-length
  ]
end
      
  

to-report peep-get-fitness [x]
  ask peeps[
    ifelse empty? disp-path
      [set x x + 1000]
      [set x x + length disp-path]
  ]
  report x
end
  
to parse-bits [b]
  let bit-iter n-values (node-num * node-num) [?]
  let ogn 0
  let dst 0
  let node-list sort airports
  ask links [die]
  foreach bit-iter [
    if item ? b = 1
      [set ogn floor (? / node-num)
      set dst ? mod node-num
      if ogn != dst [ask item ogn node-list [create-link-to item dst node-list [set color red]]]]
  ]
end

;; This procedure does the main work of the genetic algorithm.
;; We start with the old generation of solutions.
;; We choose solutions with good fitness to produce offspring
;; through crossover (sexual recombination), and to be cloned
;; (asexual reproduction) into the next generation.
;; There is also a chance of mutation occurring in each individual.
;; After a full new generation of solutions has been created,
;; the old generation dies.
to create-next-generation
  ; The following line of code looks a bit odd, so we'll explain it.
  ; if we simply wrote "LET OLD-GENERATION geneS",
  ; then OLD-GENERATION would mean the set of all genes, and when
  ; new solutions were created, they would be added to the breed, and
  ; OLD-GENERATION would also grow.  Since we don't want it to grow,
  ; we instead write "geneS WITH [TRUE]", which makes OLD-GENERATION
  ; an agentset, which doesn't get updated when new solutions are created.
  let old-generation genes with [true]

  ; Some number of the population is created by crossover each generation
  ; we divide by 2 because each time through the loop we create two children.
  ;set crossover-rate 65
  let crossover-count  (floor (population-size * crossover-rate / 100 / 2))

  repeat crossover-count
  [
    ; We use "tournament selection", with tournament size = 3.
    ; This means, we randomly pick 3 solutions from the previous generation
    ; and select the best one of those 3 to reproduce.

    let parent1 min-one-of (n-of 3 old-generation) [fitness]
    let parent2 min-one-of (n-of 3 old-generation) [fitness]

    let child-bits crossover ([bits] of parent1) ([bits] of parent2)

    ; create the two children, with their new genetic material
    ask parent1 [ hatch 1 [ set bits item 0 child-bits ] ]
    ask parent2 [ hatch 1 [ set bits item 1 child-bits ] ]
  ]

  ; the remainder of the population is created by cloning
  ; selected members of the previous generation
  repeat (population-size - crossover-count * 2)
  [
    ask min-one-of (n-of 3 old-generation) [fitness]
      [ hatch 1 ]
  ]

  ask old-generation [ die ]

  ; now we're just talking to the new generation of solutions here
  let genes-list sort genes
  foreach genes-list [
      ; there's a chance of mutations occurring
      mutate ?
      ; finally we update the fitness value for this solution
      calculate-fitness ?
  ]
end

;; ===== Mutations

;; This reporter performs one-point crossover on two lists of bits.
;; That is, it chooses a random location for a splitting point.
;; Then it reports two new lists, using that splitting point,
;; by combining the first part of bits1 with the second part of bits2
;; and the first part of bits2 with the second part of bits1;
;; it puts together the first part of one list with the second part of
;; the other.
to-report crossover [bits1 bits2]
  let split-point 1 + random (length bits1 - 1)
  report list (sentence (sublist bits1 0 split-point)
                        (sublist bits2 split-point length bits2))
              (sentence (sublist bits2 0 split-point)
                        (sublist bits1 split-point length bits1))
end

;; This procedure causes random mutations to occur in a solution's bits.
;; The probability that each bit will be flipped is controlled by the
;; MUTATION-RATE slider.
to mutate [x]  ;; gene procedure
  ;set mutation-rate .4
  ask x[
    set bits map [ifelse-value (random-float 100.0 < mutation-rate) [1 - ?] [?]]
               bits
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1104
525
110
60
4.0
1
10
1
1
1
0
0
0
1
-110
110
-60
60
1
1
1
ticks
30.0

BUTTON
48
62
149
95
NIL
setup-peeps
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
64
10
127
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
49
109
149
142
NIL
move-peeps
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
47
169
155
202
NIL
setup-genetic
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
52
225
142
258
NIL
go-genetic
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
27
279
199
312
population-size
population-size
0
200
10
2
1
NIL
HORIZONTAL

SLIDER
26
323
198
356
crossover-rate
crossover-rate
0
100
50
2
1
NIL
HORIZONTAL

SLIDER
28
365
200
398
mutation-rate
mutation-rate
0
10
0.5
.1
1
NIL
HORIZONTAL

PLOT
148
386
348
536
plot 1
ticks
fitness
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [fitness] of genes"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
