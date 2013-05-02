breed [nodes node]
breed [walkers walker]
breed [genes gene]

globals [node-num winner avg-shortest]

walkers-own [location disp-path]  ;; holds a node
nodes-own [dist visited prev]

;; Each potential solution is represented by a turtle <gene>.

genes-own [
  bits           ;; list of 0's and 1's
  fitness
]

to avg-shortesty
  set avg-shortest 0
  let all-paths []
  foreach sort nodes[
    let n1 ?
    foreach sort nodes[
      let n2 ?
      if n1 != n2 [
        ask walkers [
          set location n1
          set avg-shortest avg-shortest + dijkstra n2]
;        set all-paths sentence temp all-paths
      ]
    ]
  ]
;  let total 0
;  foreach all-paths[
;set total total + length ?]
 ; show total / length all-paths
end 

to setup
  clear-all
  set-default-shape nodes "circle"
  set node-num 10
  ;; create a random network
  create-nodes node-num [ set color blue ]
  ask nodes [ create-link-with one-of other nodes [set color green] ]
  ;; lay it out so links are not overlapping
  repeat 500 [ layout ]
  ;; leave space around the edges
  ask nodes [ setxy 0.95 * xcor 0.95 * ycor ]
  ;; put some "walker" turtles on the network
  create-walkers 1 [
    set color red
    set location one-of nodes
    move-to location
  ]
  reset-ticks
end

to layout
  layout-spring nodes links 0.5 2 1
end

to go
  ask walkers [
    set disp-path []
    let new-location one-of nodes
    set disp-path shortest-path new-location
    if (not empty? disp-path)
      [let iter n-values length disp-path [?]
       foreach iter[move-to item ? disp-path]
       set location new-location
      ]
  ]
end

to-report dijkstra [target]
  ask nodes [
    set dist 9999
    set visited false
    set prev nobody
  ]
  let unseen sort nodes
  set unseen remove location unseen
  let temp location
  ask temp [set dist 0]
  let uneigh []
  while [[visited] of target = false][
    foreach unseen [if member? ? sort [link-neighbors] of temp [
      set uneigh lput ? uneigh]
    ]
    foreach uneigh [ask ? [if dist > 1 + [dist] of temp [
      set dist 1 + [dist] of temp
      set prev temp]]]
    ask temp [set visited true]
    set unseen remove temp unseen
    if [visited] of target = true [report [dist] of target]
    set unseen sort-by [[dist] of ?1 < [dist] of ?2] unseen
    set temp first unseen
  ]
 report 999
end

to-report shortest-path [target]
  ;show "Path length: " show dijkstra target
  ifelse dijkstra target < 999 
  [
    let temp target
    let path []
    let infloop 0
    while [temp != location][
      set path fput [prev] of temp path
      set temp [prev] of temp
      set infloop infloop + 1
      if infloop > 900 [report []]
    ]
    report path
  ]
  [ report []]
end
  

to-report find-shortest-dist [target]
  let marker []
  let queue []
  set queue lput location queue
  set marker lput location marker
  let levels 0
  while [not empty? queue]
  [
    let temp first queue
    set queue but-first queue 
    if temp = target [report levels]
    ask temp [
      let children sort link-neighbors
      foreach children [if not member? ? marker [
          set marker lput ? marker
          set queue lput ? queue
      ]]
    ]
  ]
  report 9999
end

; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.


;----------------------------------------------------------------------
;----------------------------------------------------------------------
;----------------------------------------------------------------------


to setup-genetic
  ;set population-size 10
  create-genes population-size [
    set bits n-values (count nodes * count nodes) [one-of [0 1]]
    calculate-fitness
    set hidden? true  ;; the genes' locations are not used, so hide them
  ]
  tick
end

to go-genetic
  ; put some stop condition here with command [stop] once we know fitness criteria
  create-next-generation
  ;update-display
  tick
end


;; ===== Generating Solutions

;; Each solution has its "fitness score" calculated.
;; Higher scores mean "more fit", and lower scores mean "less fit".
;; The higher a fitness score, the more likely that this solution
;;   will be chosen to reproduce and create offspring solutions
;;   in the next generation.
;;
to calculate-fitness      ;; gene procedure
  set fitness 0
  parse-bits bits
  repeat 10[
    go
    set fitness walker-get-fitness fitness
  ]
;  let total-length 0
;  foreach sort nodes [
;    let n1 ?
;    foreach sort nodes [
;      let n2 ?
;      if n1 != n2 [
;        let total-length total-length + 
  set fitness fitness + 10 * (count links)
end

to-report walker-get-fitness [x]
  ask walkers[
    ifelse empty? disp-path
      [set x x + 10]
      [set x x + length disp-path]
  ]
  report x
end
  
to parse-bits [b]
  let bit-iter n-values (node-num * node-num) [?]
  let ogn 0
  let dst 0
  let node-list sort nodes
  ask links [die]
  foreach bit-iter [
    if item ? b = 1
      [set ogn floor (? / node-num)
      set dst ? mod node-num
      if ogn != dst [ask item ogn node-list [create-link-with item dst node-list [set color red]]]]
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
    ask ?[
      ; there's a chance of mutations occurring
      mutate
      ; finally we update the fitness value for this solution
      calculate-fitness
    ]
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
to mutate   ;; gene procedure
  ;set mutation-rate .4
  set bits map [ifelse-value (random-float 100.0 < mutation-rate) [1 - ?] [?]]
               bits
end

;; ===== Diversity Measures

;; Our diversity measure is the mean of all-pairs Hamming distances between
;; the genomes in the population.
to-report diversity
  let distances []
  ask genes [
    let bits1 bits
    ask genes with [self > myself] [
      set distances fput (hamming-distance bits bits1) distances
    ]
  ]
  ; The following  formula calculates how much 'disagreement' between genomes
  ; there could possibly be, for the current population size.
  ; This formula may not be immediately obvious, so here's a sketch of where
  ; it comes from.  Imagine a population of N genes, where N is even, and each
  ; gene has  only a single bit (0 or 1).  The most diverse this population
  ; can be is if half the genes have 0 and half have 1 (you can prove this
  ; using calculus!). In this case, there are (N / 2) * (N / 2) pairs of bits
  ; that differ.  Showing that essentially the same formula (rounded down by
  ; the floor function) works when N is odd, is left as an exercise to the reader.
  let max-possible-distance-sum floor (count genes * count genes / 4)

  ; Now, using that number, we can normalize our diversity measure to be
  ; between 0 (completely homogeneous population) and 1 (maximally heterogeneous)
  report (sum distances) / max-possible-distance-sum
end

;; The Hamming distance between two bit sequences is the fraction
;; of positions at which the two sequences have different values.
;; We use MAP to run down the lists comparing for equality, then
;; we use LENGTH and REMOVE to count the number of inequalities.
to-report hamming-distance [bits1 bits2]
  report (length remove true (map [?1 = ?2] bits1 bits2)) / world-width
end


; Copyright 2008 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
155
10
627
503
16
16
14.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
32
55
116
88
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
32
125
116
158
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
32
90
116
123
go once
go
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
35
170
143
203
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
22
217
112
250
NIL
go-genetic
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
639
21
839
171
NIL
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
"default" 1.0 0 -7171555 true "" "plot max [fitness] of genes"
"pen-1" 1.0 0 -12345184 true "" "plot min [fitness] of genes"
"pen-2" 1.0 0 -3508570 true "" "plot mean [fitness] of genes"

SLIDER
652
179
844
212
population-size
population-size
0
200
180
1
1
(# genes)
HORIZONTAL

SLIDER
654
223
826
256
crossover-rate
crossover-rate
0
100
70
1
1
NIL
HORIZONTAL

SLIDER
655
269
827
302
mutation-rate
mutation-rate
0
10
0.5
.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This example shows how to make turtles "walk" from node to node on a network, by following links.

## EXTENDING THE MODEL

Animate the turtles as they move from node to node.

## RELATED MODELS

* Lattice-Walking Turtles Example
* Grid-Walking Turtles Example
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.3
@#$#@#$#@
random-seed 2
setup
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
