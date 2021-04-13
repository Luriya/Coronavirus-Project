;;extensions[profiler]


turtles-own
[ spawn-x ;; the x xpawn co-ordinates of the turtle
  spawn-y
  chance-of-return ;; the chance for the turtle to turn and move back in the direction of their spawn (basically how widely they wander)
  prob-of-death ;; the chance of the turtle to die from infection
  incubate-period
  infected? ;; booleans for current status of turtle
  sick?
  asymptomatic?
  susceptible?
  infected-flag? ;; flags for the turtle to change state on the next tick
  sick-flag?
  susceptible-flag?
  immune-flag?
  remaining-immunity ;; number of immunity days remaining
  contact-list ;; the list of known contacts for the given turtle
  infection-prob ;; the probability of being infected
  counted? ;; boolean to indicate whether the user has been counted in test-and-trace
  is-isolating? ;; booleans for the current status of the turtle, whether they are shielding, isolating, tested, traced, etc.
  is-shielding?
  is-sd-used?
  is-ppe-used?
  is-self-isolating?
  is-new?
  tested?
  traced?
  contacts-alerted?
  isolation-days ;; number of isolation days remaining
  incubation-days ;; number of incubation days remaining before becoming sick or asymptomatic
  sick-time ;; how many days the turtle has been sick
  neighbours ;; agentset of the turtle's neighbours
  sex ;; 'M' or 'F'
  age ;; how old the turtle is (in years)
]

globals
[
  %infected ;; the percentages of the population with each state
  %sick
  %immune
  %asymptomatic
  deaths ;; count of the number of turtles who have died (does not include those who have left the environment)
  carrying-capacity ;; the number of turtles that can be in the world at one time
  at-risk-turtles ;; the agentset of turtles who are over 75 years old, considered 'at risk'
  lockdown-active? ;; booleans showing if a certain control procedure is active or not
  ppe-active?
  self-isolation-active?
  social-distancing-active?
  shielding-active?
  test-and-trace-active?
  number-of-contacts ;; the size of the contact list
  total-turtles ;; counts of the states of departed turtles
  total-susceptible
  total-infected
  total-sick
  total-asymptomatic
  total-immune
  overall-total-turtles
  overall-total-susceptible
  overall-total-infected
  overall-total-sick
  overall-total-asymptomatic
  overall-total-immune
  new-infected
  new-deaths
  total-cost
  b-iso
  b-shield
  b-sd
  b-ppe
  b-tt
  b-lockdown
  hospital-cost
  death-cost
]

;; Setting up the model
to setup
  clear-all
  setup-turtles
  setup-constants
  setup-globals
  update-global-variables
  update-display
  reset-ticks
  file-open "[File Location]\\testLog.txt" ; address where we want to store the log of results from runs
end

to close-file
  file-close-all
end

;; Sets up the constants of the model
to setup-constants
  set carrying-capacity 500
  set at-risk-turtles (turtles with [age >= 75 ])
end

to delete-file
  carefully [ file-delete "[File Location]\\testLog.txt" ] [ ] ; address where we want to store the log of results from runs
end

;to debug
;  setup                  ;; set up the model
;  profiler:start         ;; start profiling
;  repeat simulation-time [go]        ;; run something you want to measure
;  profiler:stop          ;; stop profiling
;  print profiler:report  ;; view the results
;  profiler:reset         ;; clear the data
;end

;; Setting up the turtles themselves, initialise values
to setup-turtles
  create-turtles number-people [
    set spawn-x random-xcor
    set spawn-y random-ycor
    set chance-of-return 20
    setxy spawn-x spawn-y
    ifelse random-float 100 <= 51 [set sex "F"] [set sex "M"] ;; 51% of Scots are female
    set-age (sex) ;; call set-age to generate an age based on sex
    set prob-of-death random-normal (chance-by-age age sex) death-chance-sd ;; pass age and sex to the chance-by-age method
    set incubate-period random-normal incubation-period incubation-period-sd
    set sick-time 0
    set infection-prob infectiousness
    set shape "person"
    set remaining-immunity 0
    set isolation-days -1
    set is-new? false
    set is-isolating? false
    set is-shielding? false
    set is-sd-used? false
    set is-ppe-used? false
    set is-self-isolating? false
    set infected-flag? false
    set sick-flag? false
    set susceptible-flag? false
    set immune-flag? false
    set tested? false
    set traced? false
    set counted? false
    set contact-list [] ;; create empty contact list
    set contacts-alerted? false
    set size 0.8
    get-susceptible ;; (almost) all turtles are susceptible by default
  ]

  ask turtles [
    set neighbours (other turtles in-radius 3) ;; compute the set of neighbours for each turtle at spawn
  ]

  ask n-of (number-people / 100)  turtles
    [ get-infected ] ;; set 10 of the population to be infected
  set overall-total-turtles (overall-total-turtles + number-people)
end

;; Initialising global variables
to setup-globals
  set ppe-active? false
  set lockdown-active? false
  set shielding-active? false
  set self-isolation-active? false
  set test-and-trace-active? false
  set social-distancing-active? false
  set total-turtles 0
  set total-susceptible 0
  set total-infected 0
  set total-sick 0
  set total-asymptomatic 0
  set total-immune 0
  set new-infected 0
  set new-deaths 0

  set b-iso ifelse-value (self-isolation? = true) [1][0]
  set b-shield ifelse-value (shielding? = true) [1][0]
  set b-sd ifelse-value (social-distancing? = true) [1][0]
  set b-ppe ifelse-value (ppe? = true) [1][0]
  set b-tt ifelse-value (test-and-trace? = true) [1][0]
  set b-lockdown ifelse-value (lockdown? = true) [1][0]

end

;; Called to turn turtle infected
to get-infected
  set infected? true
  set susceptible? false
  set sick? false
  set remaining-immunity 0
  set incubation-days 0
  set overall-total-infected (overall-total-infected + 1)
end

;; Called to turn turtle sick
to get-sick
  if incubation-days >= incubate-period [ ;; only triggers if the incubation period has passed for the turtle
    set sick? true
    set infected? false
    set susceptible? false
    set remaining-immunity 0
    set new-infected new-infected + 1
    set overall-total-sick (overall-total-sick + 1)
    if random-float 100 <= percentage-asymp
    [
      set asymptomatic? true
      set overall-total-asymptomatic (overall-total-asymptomatic + 1)
    ] ;; there is a chance based on the percentage-asymp slider that a turtle will be asymptomatic as well as sick
  ]
end

;; Called to turn turtle susceptible
to get-susceptible
  set sick? false
  set asymptomatic? false
  set infected? false
  set susceptible? true
  set remaining-immunity 0
  set overall-total-susceptible (overall-total-susceptible + 1)
  set sick-time 0
end

;; Called to turn turtle immune
to become-immune
  set sick? false
  set asymptomatic? false
  set susceptible? false
  set sick-time 0
  set overall-total-immune (overall-total-immune + 1)
  set remaining-immunity immunity-duration ;; Start the immunity countdown
end

;; Main procedure, runs the simulation
to go
  file-write count turtles with [infected?]
  file-write count turtles
  file-write count turtles with [sick?]
  file-write count turtles with [asymptomatic?]
  file-write count turtles with [infected?] * 0.113
  file-write new-deaths
  file-print ""
  file-flush

  set new-infected 0
  set new-deaths 0
  ask turtles [
    set neighbours (other turtles in-radius 1) ;; update neighbours
    set counted? false
  ]
  count-contacts ;; update contacts
  if test-and-trace? [record-contacts]

  ;; Adjust values based on status
  ask turtles [
    if immune? [ ifelse remaining-immunity = 1 [set susceptible-flag? true][set remaining-immunity remaining-immunity - 1 ]]
    if infected? [
      set incubation-days incubation-days + 1
      set sick-flag? true
    ]
    if sick? [
     set sick-time sick-time + 1
     recover-or-die
     infect
    ]
    if not is-isolating? [move]
    if is-self-isolating? [
      if susceptible? or immune? [release-agent]
    ]
  ]
  migrate ;; call the migrate procedure to move turtles in and out of the area

  ;; Call update procedures
  process-changes
  update-global-variables
  ;;update-display
  update-measures
  tick
end

to advance
    set new-infected 0
  set new-deaths 0
  ask turtles [
    set neighbours (other turtles in-radius 1) ;; update neighbours
    set counted? false
  ]
  count-contacts ;; update contacts
  if test-and-trace? [record-contacts]

  ;; Adjust values based on status
  ask turtles [
    if immune? [ ifelse remaining-immunity = 1 [set susceptible-flag? true][set remaining-immunity remaining-immunity - 1 ]]
    if infected? [
      set incubation-days incubation-days + 1
      set sick-flag? true
    ]
    if sick? [
     set sick-time sick-time + 1
     recover-or-die
     infect
    ]
    if not is-isolating? [move]
    if is-self-isolating? [
      if susceptible? or immune? [release-agent]
    ]
  ]
  migrate ;; call the migrate procedure to move turtles in and out of the area

  ;; Call update procedures
  process-changes
  update-global-variables
  ;;update-display
  update-measures
    tick
end

;; Called at the end of go to change turtle statuses then, rather than midway through a sweep
to process-changes
  ask turtles with [infected-flag?] [
    set infected-flag? false
    get-infected
  ]
  ask turtles with [sick-flag?] [
    set sick-flag? false
    get-sick
  ]
  ask turtles with [susceptible-flag?] [
    set susceptible-flag? false
    get-susceptible
  ]
  ask turtles with [immune-flag?] [
    set immune-flag? false
    become-immune
  ]
end

;; Update the contacts for each turtle
to count-contacts
  set number-of-contacts 0

  ;; Only turtles who are not self isolating can be counted
  ask turtles with [not is-self-isolating?] [
    set counted? true
    let these-contacts (count neighbours with [not is-self-isolating? and not counted?])
    set number-of-contacts (number-of-contacts + these-contacts)
  ]

  ;;ask turtles [set counted? false] ;; reset counted boolean
end

;; Update the contact list for each relevant turtle
to record-contacts
  if %sick >= test-and-trace-threshold [
    ask (turtle-set turtles with [sick? or asymptomatic? or infected?]) [
      if length contact-list < count neighbours [
        let contacts [self] of neighbours with [not is-self-isolating?]
        foreach contacts [
          contact ->
          if not member? contact contact-list [
            set contact-list lput contact contact-list
          ]
        ]
      ]
    ]
  ]
end

;; Update the percentage counts of turtles with various states
to update-global-variables
  if count turtles > 0
    [ set %infected (count turtles with [ infected? ] / count turtles) * 100
      set %sick (count turtles with [ sick? ] / count turtles) * 100
      set %immune (count turtles with [ immune? ] / count turtles) * 100
      set %asymptomatic (count turtles with [ asymptomatic? ] / count turtles) * 100 ]
end

;; Set the colors of the turtles relative to their current status
to update-display
  ask turtles
    [ set color ifelse-value sick? [ red ] [ ifelse-value immune? [ grey ] [ green ] ]
      if sick? and asymptomatic? [set color orange]
      if infected? [set color yellow]]
end

;; Start and stop the various control measures based on the boolean status
to update-measures
  if ppe? [
    ifelse %sick >= protection-threshold [
      if not ppe-active? [start-ppe]
    ] [
      if ppe-active? [end-ppe]
    ]
  ]

  if lockdown? [
    ifelse %sick >= lockdown-threshold [
      if not lockdown-active? [start-lockdown]
    ] [
      if lockdown-active? [end-lockdown]
    ]
  ]

  if shielding? [
    ifelse %sick >= shielding-threshold [
      if not shielding-active? [start-shielding]
    ] [ ;; else
      if shielding-active? [end-shielding]
    ]
  ]

  if self-isolation? [
    ifelse %sick >= isolation-threshold [
      if not self-isolation-active? [start-isolation]
    ] [
      if self-isolation-active? [end-isolation]
    ]
  ]

  if test-and-trace? [
    ifelse %sick >= test-and-trace-threshold [
      if not test-and-trace-active? [start-test-and-trace]
    ] [
      if test-and-trace-active? [  ]
    ]
    ;; Attempt to get tested turtles to isolate
    ask (turtle-set turtles with [sick? or asymptomatic? or infected?]) with [tested?] [
      if random-float 100 <= tt-isolation-compliance [
        set is-self-isolating? true
        isolate-agent
      ]
    ]
  ]

  if social-distancing? [
    ifelse %sick >= social-distancing-threshold [
      if not social-distancing-active? [start-social-distancing]
    ] [
      if social-distancing-active? [end-social-distancing]
    ]
  ]
end

;; Update the infection rates based on whether or not PPE and social distancing are active
to update-infection-rates
  ask turtles [
    ifelse is-ppe-used? [
      ifelse is-sd-used? [
        set infection-prob (0.2 * 0.8 * infectiousness)
      ] [
        set infection-prob (0.2 * infectiousness)
      ]
    ] [
      ifelse is-sd-used? [
        set infection-prob (0.8 * infectiousness)
      ] [
        set infection-prob infectiousness
      ]
    ]
  ]
end

;; Isolate a turtle in their home
to isolate-agent
  set is-isolating? true
  set shape "house"
end

;; Release turtle from home
to release-agent
  set is-isolating? false
  set shape "person"
end

;; Start PPE
to start-ppe
  ask turtles [
    if random-float 100 <= protection-compliance [set is-ppe-used? true]
  ]
  set ppe-active? true
  update-infection-rates
end

;; End PPE
to end-ppe
  ask turtles with [is-ppe-used?] [
    set is-ppe-used? false
  ]
  set ppe-active? false
  update-infection-rates
end

;; Start lockdown
to start-lockdown
  ask turtles [
    if random-float 100 <= lockdown-compliance [isolate-agent]
  ]
  set lockdown-active? true
  isolate
end

;; End lockdown
to end-lockdown
  ask turtles [
    if not is-shielding? or not member? self at-risk-turtles [
      release-agent
    ]
  ]
  set lockdown-active? false
end

;; Start shielding
to start-shielding
  ask at-risk-turtles [
    if random-float 100 <= shielding-compliance [
      set is-shielding? true
      isolate-agent
    ]
  ]
  set shielding-active? true
  isolate
end

;; End shielding
to end-shielding
  if not lockdown-active? [
    ask at-risk-turtles with [not is-self-isolating?] [
      set is-shielding? false
      release-agent
    ]
  ]
  set shielding-active? false
end

;; Start isolation
to start-isolation
  ;; Only sick turtles will isolate
  ask turtle-set turtles with [sick?] [
    if random-float 100 <= isolation-compliance [
      set is-self-isolating? true
      isolate-agent]
  ]
  set self-isolation-active? true
  isolate
end

;; End isolation
to end-isolation
  ;; Only triggered if lockdown is not active - otherwise, most everyone should be isolating
  if not lockdown-active? [
    ask turtle-set turtles with [is-self-isolating? and not is-shielding? and (not sick? or not ((asymptomatic? or infected?) and (tested?)))] [
      set is-self-isolating? false
      release-agent
    ]
  ]
  ;; Isolation only completely ends when all turtles have left isolation
  if not any? turtles with [is-self-isolating? and not is-shielding? and (sick? or ((asymptomatic? or infected?) and (tested?)))] [
    set self-isolation-active? false
  ]

end

;; Start T&T
to start-test-and-trace
  set test-and-trace-active? true
  test
  trace
end

;; End T&T
to end-test-and-trace
  set test-and-trace-active? false
end

;; Start social distancing
to start-social-distancing
  ask turtles [
    if random-float 100 <= social-distancing-compliance [set is-sd-used? true]
  ]
  set social-distancing-active? true
  update-infection-rates
end

;; End social distancing
to end-social-distancing
  ask turtles with [is-sd-used?] [
    set is-sd-used? false
  ]
  set social-distancing-active? false
  update-infection-rates
end

;; Test a percentage of the population (based on the slider value)
to test
  ask turtle-set turtles with [not tested?] [
    if random-float 100 < test-coverage [
      set tested? true
      if infected? or asymptomatic? [
        set new-infected new-infected + 1
      ]
    ]
  ]
end

;; Perform tracing on tested turtle's contacts
to trace
  ask turtle-set turtles with [tested?] [
    if not contacts-alerted? [
      foreach contact-list [
        contact -> if contact != nobody [
          ;; Based on slider value, a set number of traced contacts will be reached
          if random-float 100 < trace-contacts-reached [
            ask contact [
              ;; Percentage chance for traced contact to self-isolate
              if random-float 100 <= tt-isolation-compliance [
                set is-self-isolating? true
                isolate-agent
              ]
            ]
          ]
        ]
      ]
      set contacts-alerted? true
    ]
  ]
end

;; Update isolation countdowns for relevant isolating turtles
to isolate
  let agents-to-check nobody ;; agents for whom isolation has to progress
  set agents-to-check (turtle-set turtles with [is-isolating? or is-shielding?] agents-to-check)
  ask agents-to-check [update-isolation-countdown]
end

;; Update the isolation countdowns, or release the agent if isolation time has ended
to update-isolation-countdown
  ;; -1 is the default
  if isolation-days = -1 [
    stop
    isolate-agent
    set isolation-days 30
  ]

  ifelse isolation-days = 0 [
    if not lockdown-active? [
      if not shielding-active?  [
        release-agent
        set is-self-isolating? false
        set isolation-days -1
        set traced? false
      ]
    ]
  ] [ ;; else

    set shape "house"
    set isolation-days (isolation-days - 1) ;; Since this procedure is called each tick, this value is decremented on each step/tick
  ]
end

;; Move turtles around
to move
  rt random 10
  lt random 10
  fd 0.5
  ;; Turtles will attempt to distance themselves from others if social distancing is active
  if (social-distancing-active?) [
    if any? other turtles-here [
      rt random 90
      fd 1
    ]
  ]
  ;; If the turtle strays far enough from spawn they have a slowly increasing chance to turn back based on their distance from spawn
  if [distance myself] of patch spawn-x spawn-y >= 2.5 [
    set chance-of-return 10 + (turtle-drift-rate * [distance myself] of patch spawn-x spawn-y)
    if random-float 100 <= chance-of-return [
      facexy spawn-x spawn-y
      rt random 45
      lt random 45
      fd 0.5
    ]
  ]
end

;; If a turtle is sick it can infect other non-sick, non-immune turtles (who are not confined to their homes, i.e. shielding and isolating)
to infect ;; turtle procedure
  ask other turtles-here with [susceptible? and not immune? and not (is-isolating? or is-shielding?)]
    [ if random-float 100 <= infection-prob
      [ set infected-flag? true ] ]
end

;; A sick turtle will either recover or die based on a random dice roll and if it exceeds the probability of death or not
to recover-or-die ;; turtle procedure
  if sick-time > avg-recovery-time ;; if survived to the average recovery time...
    [ ifelse random-float 100 >= prob-of-death
      [ if immunity? [set immune-flag? true] ] ;; become immune
      [ set deaths deaths + 1 ;; die
        set new-deaths new-deaths + 1
        die ] ]
end

;; Move turtles in and out of the environment to simulate more realistic movement (base is 1% of turtles can be removed or added)
to migrate
  ;; If the max limit of turtles has not been reached
  if count turtles < carrying-capacity and random-float 100 < migration-rate [
    ;; Either create and spawn a new turtle...
    ifelse random 2 = 1 [
      create-turtles 1 [
        set chance-of-return 20
        ifelse random-float 100 <= 51 [set sex "F"] [set sex "M"] ;; 51% of Scots are female
        set-age (sex) ;; call set-age to generate an age based on sex
        set prob-of-death random-normal (chance-by-age age sex) death-chance-sd ;; pass age and sex to the chance-by-age method
        set incubate-period random-normal incubation-period incubation-period-sd
        set sick-time 0
        set infection-prob infectiousness
        set shape "person"
        set remaining-immunity 0
        set isolation-days -1
        set is-new? false
        set is-isolating? false
        set is-shielding? false
        set is-sd-used? false
        set is-ppe-used? false
        set is-self-isolating? false
        set infected-flag? false
        set sick-flag? false
        set susceptible-flag? false
        set immune-flag? false
        set tested? false
        set traced? false
        set counted? false
        set contact-list [] ;; create empty contact list
        set contacts-alerted? false
        get-susceptible
        set size 0.8
        ifelse immunity?[let choice random 4 (ifelse choice = 0 [get-susceptible]
          choice = 1 [get-infected]
          choice = 2 [get-sick]
          choice = 3 [become-immune])]
        [let choice random 3 (ifelse choice = 0 [get-susceptible]
          choice = 1 [get-infected]
          choice = 2 [get-sick])]
        set spawn-x random-xcor
        set spawn-y random-ycor
        setxy spawn-x spawn-y
      ]
      set overall-total-turtles (overall-total-turtles + number-people)
    ]
    ;; Or remove one, recording their last state to the relevant variable (but don't count them as a death)
    [
      ask one-of turtles [
        if sick? [set total-sick (total-sick + 1)]
        if immune? [set total-immune (total-immune + 1)]
        if susceptible? [set total-susceptible (total-susceptible + 1)]
        if asymptomatic? [set total-asymptomatic (total-asymptomatic + 1)]
        if infected? [set total-infected (total-infected + 1)]
        set total-turtles (total-turtles + 1)
        die
      ]
    ]
  ]

end

;; For retreiving the amount of immune turtles (for example when using the graph)
to-report immune?
  report remaining-immunity > 0
end

;; Procedure to set age based on the sex of the turtles
to set-age [#sex] ;; based on Scottish population estimates for 2020 based on 2019 census data (https://www.ons.gov.uk/peoplepopulationandcommunity)
  ifelse #sex = "F" [
    let p random-float 100
    if p <= 4.61 [set age 0 + random 5]
    if p >= 4.62 and p <= 15.00 [set age 5 + random 10]
    if p >= 15.01 and p <= 19.87 [set age 15 + random 5]
    if p >= 19.88 and p <= 25.88 [set age 20 + random 5]
    if p >= 25.89 and p <= 51.69 [set age 25 + random 20]
    if p >= 51.70 and p <= 79.25 [set age 45 + random 20]
    if p >= 79.26 and p <= 90.17 [set age 65 + random 10]
    if p >= 90.18 and p <= 97.05 [set age 75 + random 10]
    if p >= 97.06 [set age 85 + random 36]
  ] [
    let p random-float 100
    if p <= 5.14 [set age 0 + random 5]
    if p >= 5.15 and p <= 11.42 [set age 5 + random 10]
    if p >= 11.43 and p <= 21.91 [set age 15 + random 5]
    if p >= 21.92 and p <= 28.40 [set age 20 + random 5]
    if p >= 28.41 and p <= 54.95 [set age 25 + random 20]
    if p >= 54.96 and p <= 82.10 [set age 45 + random 20]
    if p >= 82.11 and p <= 92.62 [set age 65 + random 10]
    if p >= 92.63 and p <= 98.26 [set age 75 + random 10]
    if p >= 98.27 [set age 85 + random 36]
  ]
end

;; Procedure to set the chance of death based on the age and sex of the turtle
to-report chance-by-age [#age #sex] ;; based on opendata statistics for Scotland showing deaths against cases by age group (https://www.opendata.nhs.scot)
  let p 0
  ifelse #sex = "F" [
    if #age >= 0 and #age <= 4 [set p ((0 / 680) * 100)]
    if #age >= 5 and #age <= 14 [set p ((0 / 1899) * 100)]
    if #age >= 15 and #age <= 19 [set p ((0 / 4200) * 100)]
    if #age >= 20 and #age <= 24 [set p ((0 / 4730) * 100)]
    if #age >= 25 and #age <= 44 [set p ((11 / 15780) * 100)]
    if #age >= 45 and #age <= 64 [set p ((111 / 15455) * 100)]
    if #age >= 65 and #age <= 74 [set p ((227 / 2810) * 100)]
    if #age >= 75 and #age <= 84 [set p ((520 / 2938) * 100)]
    if #age >= 85 [set p ((859 / 3128) * 100)]
  ] [
    if #age >= 0 and #age <= 4 [set p ((0 / 681) * 100)]
    if #age >= 5 and #age <= 14 [set p ((0 / 1835) * 100)]
    if #age >= 15 and #age <= 19 [set p ((0 / 3404) * 100)]
    if #age >= 20 and #age <= 24 [set p ((1 / 4094) * 100)]
    if #age >= 25 and #age <= 44 [set p ((14 / 12018) * 100)]
    if #age >= 45 and #age <= 64 [set p ((198 / 12077) * 100)]
    if #age >= 65 and #age <= 74 [set p ((382 / 3139) * 100)]
    if #age >= 75 and #age <= 84 [set p ((745 / 2581) * 100)]
    if #age >= 85 [set p ((609 / 1535) * 100)]
  ]
  report p
end

to startup
  setup-constants ;; so that carrying-capacity can be used as upper bound of number-people slider
end
@#$#@#$#@
GRAPHICS-WINDOW
240
10
738
509
-1
-1
19.6
1
10
1
1
1
0
1
1
1
-12
12
-12
12
1
1
1
ticks
60.0

SLIDER
40
200
234
233
avg-recovery-time
avg-recovery-time
0.0
99.0
15.0
1.0
1
days
HORIZONTAL

SLIDER
40
162
234
195
infectiousness
infectiousness
0.0
99.0
79.0
1.0
1
%
HORIZONTAL

BUTTON
62
83
132
118
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
138
83
213
118
go
repeat simulation-time [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
750
10
1370
465
Current View
days
people
0.0
730.0
0.0
600.0
true
true
"" ""
PENS
"sick" 1.0 0 -2674135 true "" "plot count turtles with [ sick? ]"
"asympt." 1.0 0 -955883 true "" "plot count turtles with [ asymptomatic? ]"
"infected" 1.0 0 -1184463 true "" "plot count turtles with [ infected? ]"
"suscep." 1.0 0 -13840069 true "" "plot count turtles with [ susceptible? ]"
"count" 1.0 0 -13791810 true "" "plot count turtles"
"immune" 1.0 0 -7500403 true "" "plot count turtles with [ immune? ]"
"deaths" 1.0 0 -16777216 true "" "plot deaths"
"new inf" 1.0 0 -7858858 true "" "plot new-infected"

SLIDER
40
10
234
43
number-people
number-people
10
5000
250.0
10
1
NIL
HORIZONTAL

MONITOR
1040
465
1115
510
NIL
%infected
2
1
11

MONITOR
1110
465
1184
510
NIL
%immune
2
1
11

SLIDER
50
240
222
273
percentage-asymp
percentage-asymp
0
100
25.0
1
1
%
HORIZONTAL

SLIDER
50
280
222
313
incubation-period
incubation-period
0
100
5.0
1
1
days
HORIZONTAL

SWITCH
640
645
787
678
social-distancing?
social-distancing?
0
1
-1000

SWITCH
455
520
567
553
lockdown?
lockdown?
0
1
-1000

SWITCH
270
520
373
553
ppe?
ppe?
0
1
-1000

SWITCH
630
520
737
553
shielding?
shielding?
0
1
-1000

SWITCH
440
640
582
673
test-and-trace?
test-and-trace?
0
1
-1000

SWITCH
255
640
387
673
self-isolation?
self-isolation?
0
1
-1000

SWITCH
85
520
192
553
immunity?
immunity?
0
1
-1000

SLIDER
50
45
222
78
simulation-time
simulation-time
0
730
365.0
5
1
ticks
HORIZONTAL

SLIDER
50
400
222
433
migration-rate
migration-rate
0.00
90
10.0
0.01
1
%
HORIZONTAL

MONITOR
830
465
887
510
NIL
deaths
17
1
11

SLIDER
235
560
412
593
protection-threshold
protection-threshold
0
100
10.0
1
1
%
HORIZONTAL

MONITOR
1370
10
1447
55
NIL
ppe-active?
17
1
11

SLIDER
425
560
597
593
lockdown-threshold
lockdown-threshold
0
100
21.0
1
1
%
HORIZONTAL

SLIDER
425
595
602
628
lockdown-compliance
lockdown-compliance
0
100
64.0
1
1
%
HORIZONTAL

SLIDER
605
595
782
628
shielding-compliance
shielding-compliance
0
100
84.0
1
1
%
HORIZONTAL

MONITOR
1370
55
1477
100
NIL
lockdown-active?
17
1
11

SLIDER
605
560
777
593
shielding-threshold
shielding-threshold
0
100
15.0
1
1
%
HORIZONTAL

MONITOR
1370
100
1472
145
NIL
shielding-active?
17
1
11

MONITOR
960
465
1040
510
No. shielding
count turtles with [is-shielding?]
17
1
11

MONITOR
885
465
960
510
No. isolating
count turtles with [is-isolating? and not is-shielding?]
17
1
11

MONITOR
750
465
832
510
NIL
count turtles
17
1
11

SLIDER
235
680
407
713
isolation-threshold
isolation-threshold
0
100
15.0
1
1
%
HORIZONTAL

SLIDER
235
710
407
743
isolation-compliance
isolation-compliance
0
100
52.0
1
1
%
HORIZONTAL

MONITOR
1370
145
1492
190
NIL
self-isolation-active?
17
1
11

SLIDER
420
680
622
713
test-and-trace-threshold
test-and-trace-threshold
0
100
18.0
1
1
%
HORIZONTAL

SLIDER
420
715
607
748
test-coverage
test-coverage
0
100
80.0
1
1
%
HORIZONTAL

SLIDER
395
750
627
783
trace-contacts-reached
trace-contacts-reached
0
100
78.0
1
1
%
HORIZONTAL

MONITOR
1370
190
1507
235
NIL
test-and-trace-active?
17
1
11

SLIDER
626
680
838
713
social-distancing-threshold
social-distancing-threshold
0
100
10.0
1
1
%
HORIZONTAL

TEXTBOX
15
20
165
38
500
11
0.0
1

TEXTBOX
20
55
170
73
365
11
0.0
1

TEXTBOX
10
170
160
188
79%
11
0.0
1

TEXTBOX
20
410
170
428
1%
11
0.0
1

SLIDER
415
785
607
818
tt-isolation-compliance
tt-isolation-compliance
0
100
60.0
1
1
%
HORIZONTAL

MONITOR
1370
235
1517
280
NIL
social-distancing-active?
17
1
11

SLIDER
50
440
222
473
turtle-drift-rate
turtle-drift-rate
0
20
10.0
1
1
NIL
HORIZONTAL

TEXTBOX
20
450
35
468
10
11
0.0
1

PLOT
1310
300
1895
760
Total
people
days
0.0
730.0
0.0
2000.0
true
true
"" ""
PENS
"sick" 1.0 0 -2674135 true "" "plot count turtles with [sick?] + total-sick"
"asymp." 1.0 0 -955883 true "" "plot count turtles with [asymptomatic?] + total-asymptomatic"
"infected" 1.0 0 -1184463 true "" "plot count turtles with [infected?] + total-infected"
"suscep." 1.0 0 -13840069 true "" "plot count turtles with [susceptible?] + total-susceptible"
"total" 1.0 0 -13791810 true "" "plot count turtles + total-turtles"
"immune" 1.0 0 -7500403 true "" "plot count turtles with [immune?] + total-immune"
"pen-6" 1.0 0 -6459832 true "" "plot overall-total-infected"

SLIDER
630
715
832
748
social-distancing-compliance
social-distancing-compliance
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
240
595
412
628
protection-compliance
protection-compliance
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
45
320
227
353
incubation-period-sd
incubation-period-sd
0
8
1.0
1
1
days
HORIZONTAL

SLIDER
50
360
222
393
death-chance-sd
death-chance-sd
0
30
15.0
1
1
%
HORIZONTAL

PLOT
1545
25
1860
275
New Infections
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot new-infected"

BUTTON
95
125
172
158
advance
advance
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
55
480
227
513
immunity-duration
immunity-duration
0
1000
40.0
20
1
NIL
HORIZONTAL

MONITOR
1245
670
1310
715
NIL
total-cost
17
1
11

TEXTBOX
25
620
175
646
TURNED OFF T&T FROM STOPPING - REMEMBER
11
0.0
1

MONITOR
1245
715
1310
760
total-inf
overall-total-infected
17
1
11

@#$#@#$#@
## WHAT IS IT?
This model aims to simulate the spread of the disease SARS-CoV-2 (or Coronavirus) through use of agent-based modelling, as well as the various parameters and methods that can be used to control the spread.

The model focuses on a small area of a populated town or city, and shows how within a small local community, disease can still spread rapidly, but also shows that disease mitigation methods can be effective at smaller, local levels too.

Ultimately the goal of this model is to identify which set of procedures and settings help to keep the spread of Coronavirus to a minimum while also keeping costs down.

## HOW IT WORKS
Turtles will move about at random, being lightly tethered to their spawn location and therefore generally hovering around a certain area of the simulation environment.
10 turtles are initialised as being infected, while the rest are healthy.
As the turtles move around, they can become infected by a sick individual, at which point the newly infected turtle will begin an incubation period before they become sick, with a chance to be asymptomatic.

When the turtles reach the end of the average recovery time, they will either recover from illness and become immune, or die and be removed from the simulation.
Turtles can leave and enter the simulation environment throughout the run, which helps to provide a more accurate portrayal of real life movement in and out of the area.
The status of the various sliders and switches are used during setup to provide a large amount of the variables used in the simulation, all of which are able to be tweaked by the user.

During the simulation, two graphical outputs are written to; one with the total amount of infected turtles, sick turtles, and so on, and another which focuses on the current instance and therefore does not include departed turtles.
On the monitor, turtles' colours are changed based on their current status, and the icon is changed from a person to a house if they are isolating or shielding for whatever reason. The colours used are the same ones used on the graphs, with yellow representing infected turtles, for example.

## HOW TO USE IT
By adjusting the various sliders and switches to the user's preference, they can create a setup that they like. When clicking 'Setup' the model takes these values and sets up the environment along with spawning and positioning the turtles in the environment.
The user should be able to note that with the increased amount of control procedures they select, the death count and overall spread of disease should decrease.
Stronger compliance with these procedures will also have a noticeable impact.
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count turtles with [sick?]</metric>
    <metric>deaths</metric>
    <metric>count turtles + total-turtles</metric>
    <metric>count turtles with [sick?] + total-sick</metric>
    <enumeratedValueSet variable="ppe?">
      <value value="true"/>
      <value value="false"/>
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="social-distancing?">
      <value value="true"/>
      <value value="true"/>
      <value value="false"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
1
@#$#@#$#@
