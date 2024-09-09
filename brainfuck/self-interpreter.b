Matryoshka Brainfuck Interpreter (mbfi) version 2

Made by Ørjan Johansen 2021

Version 2: Changed from a modified dbfilike dispatch to a nested loop case
match like Clive Gifford's cgbfi

Most of parsing and bracket matching code is from Daniel B Cristofani's dbfi

General tape layout most of the time:
(left simulated tape)000
(simulated code before IP)0?(code after IP)
000(simulated right tape starting with current cell)

>>> Add three more padding cells to the left of simulated code
Parser loop mostly unchanged from dbfi
>>>+[
 [-]>>[-]
 ++>+>+++++++[<++++>>++<-]++>>+>+>+++++[>++>++++++<<-]+>>>,<++[
  [>[->>]<[>>]<<-]
  <[<]<+>>[>]>
  [<+>-
   [[<+>-]>]
   <[
    [[-]<]
    Marker cell is no longer set here
    <-[
     <+++++++++>[<->-]>
     + Set process another character flag here (just 1) instead
     >
    ]>>
   ]
  ]<<
 ]<
]
Just after simulated code
<[<]> Go to first simulated code instruction and enter main interpreter loop
[ At simulated IP (0 0 'i)
 [<<+>+>-] Make two copies of instruction
 +< Set flag and go to second instruction copy (i 'i 1)

 Match instruction with nested decrements/loops
 Instructions are listed in reverse order of dbfi
 -
 [-
  [-
   [-
    [-
     [-
      [-
       [-
        Increment instruction (i '0 1)

        No other instructions left so must match
        >[>]>>> Go to simulated current cell
        + Perform instruction on simulated current cell
        << Go to middle of padding area (0 '0 0)
       ]

       After each match loop there are three possible local configurations:
        (i '0 1) This loop level matched and its instruction will run
        (0 '0 0) An instruction already ran; now in the right side padding
                 In this case the actual simulated IP will be in (i 0 1) form
        (i '0 0) An instruction already ran; now in the simulated IP
                 (This option is first used by the Move Right instruction)

       Input instruction

       > Go to flag
       [ Test flag for whether instruction should run
        [>]>>>,< Otherwise almost identical to increment
       ]
       In padding area regardless of branch taken (0 0 '0)
       < Go to middle of padding area
      ]
      >[[>]>>>-<]< Decrement instruction
     ]
     >[[>]>>>.<]< Output instruction
    ]>
    [ Move left instruction: This is the only one that starts its work
      to the left of the simulated code (i 0 '1)
     <<[<] Go to the left of the simulated code (0 0 '0 j)
     + Set flag to shorten padding
     <<< Go to old simulated left_of_current cell and loop to move its value
     [ At ((ltape) 'o 0 0 1 (code) 0 0 n (rtape))
      - Decrement
      >>>[[>]>]> Go to new simulated current cell (0 0 'n)
      + Increment
      <<<[[<]<]< Go back to old simulated left_of_current cell and loop again
     ]
     >>>- Clear temporary 1 padding to the left of simulated code
     > Go to leftmost end of simulated code and enter loop to shift code
     [[[<+>-]>]>] Shift values one cell leftward until meeting two zeros in a
                  row
    ]< At (0 '0 0) of old or new padding regardless of branch taken
   ]>
   [ Move right instruction
    [>] Go to the right of the simulated code ('0 0 0 c)
    + Set flag to shorten padding
    >>> Go to old current cell and loop to move its value
    [ At ((ltape) n 0 0 (code) 1 0 0 'o (rtape))
     - Decrement
     <<<[[<]<]< Go three cells to the left of the simulated code
     + Increment
     >>>[[>]>]> Go back to old simulated current cell and loop again
    ]
    <<<- Clear temporary 1 padding to the right of simulated code
    < Go to rightmost end of simulated code and enter loop to shift it
    [[[>+<-]<]<] Shift values one cell rightward until meeting two zeros in a
                 row
    >>>[>]>- Go to 1 of simulated IP and clear it (i 0 '0)
   ]<
  ]>
  [ Start loop instruction
   [>]>>+ Go to padding and set flag just before simulated current cell
   > Go to simulated current cell (0 0 1 'c)
   [<-]< If not zero clear flag and go to middle of padding
         If zero go to flag (and enter loop)
   [
    -<<<[<]> Clear flag and go to 1 of simulated IP (1 0 '1)
             reinterpreting this as starting depth for bracket matching
    [-<+>>-[<<+>++>-[<->[<<+>>-]]]<[>+<-]>] Unchanged from dbfi
    < Go to first zero of new simulated IP (j '0 0)
   ]
   > Go to last zero of padding or simulated IP
  ]<
 ]>
 [ End loop instruction
  [>]>>+ Go to padding and set flag just before simulated current cell
  > Go to simulated current cell and enter loop if nonzero (0 0 1 'c)
  [
   <-<<<[<]< Clear flag and go to 1 encoding current right bracket ('1 0 1)
            reinterpreting this as starting depth for bracket matching
            and the 1 of the simulated IP as the moved right bracket
   [+>+<<-[>-->+<<-[>+<[>>+<<-]]]>[<+>-]<] Unchanged from dbfi ('0 0 2)
   ++>>-- Move found left bracket leftwards and go to the second zero
          of simulated IP (2 0 '0)
  ]
  At simulated IP (j 0 '0) or simulated current cell (0 0 1 'c)
  <[-<]> If the latter then clear flag and go to it (0 0 '0 c)
 ]
 At simulated IP (i 0 '0) or in padding (0 0 '0)
 <+< Set flag and enter loop to test ('i 1 0  or  '0 1 0)
 [>-]> Clear flag and go to it if at simulated IP; then go right
 At simulated IP (i 0 '0) or in padding (0 '1 0)
 [
  -<<[<] If in padding clear flag and go to simulated IP (i '0 1)
  >- Go to 1 of simulated IP and clear it converging branches
 ]
 > Go right to next instruction code cell (or 0 beyond end of simulated code)
]
