---- MODULE BarIconFirstStart ----
EXTENDS Naturals

CONSTANTS MaxAttempts, CheckProcGuard, CheckDefaultedGuard

VARIABLES procRunning, procAdds, fileHasWidget, barHasWidget, reloadPending,
          defaulted, attempts, timerArmed, defaultedWrittenDuringScript,
          autoAddAfterDefaulted, autoAddAfterUserOff, userTurnedOff

vars == <<procRunning, procAdds, fileHasWidget, barHasWidget, reloadPending,
          defaulted, attempts, timerArmed, defaultedWrittenDuringScript,
          autoAddAfterDefaulted, autoAddAfterUserOff, userTurnedOff>>

Init ==
  /\ procRunning = FALSE /\ procAdds = FALSE
  /\ fileHasWidget \in BOOLEAN
  /\ barHasWidget = fileHasWidget
  /\ reloadPending = FALSE
  /\ defaulted = FALSE
  /\ attempts = 0
  /\ timerArmed = TRUE
  /\ defaultedWrittenDuringScript = FALSE
  /\ autoAddAfterDefaulted = FALSE
  /\ autoAddAfterUserOff = FALSE
  /\ userTurnedOff = FALSE

TimerFires ==
  /\ timerArmed
  /\ IF CheckDefaultedGuard /\ defaulted
       THEN /\ timerArmed' = FALSE
            /\ UNCHANGED <<procRunning, procAdds, defaulted, attempts,
                           defaultedWrittenDuringScript, autoAddAfterDefaulted, autoAddAfterUserOff>>
     ELSE IF CheckProcGuard /\ procRunning
       THEN /\ timerArmed' = TRUE
            /\ UNCHANGED <<procRunning, procAdds, defaulted, attempts,
                           defaultedWrittenDuringScript, autoAddAfterDefaulted, autoAddAfterUserOff>>
     ELSE IF barHasWidget
       THEN /\ defaulted' = TRUE
            /\ defaultedWrittenDuringScript' = (defaultedWrittenDuringScript \/ procRunning)
            /\ timerArmed' = FALSE
            /\ UNCHANGED <<procRunning, procAdds, attempts, autoAddAfterDefaulted, autoAddAfterUserOff>>
     ELSE IF attempts < MaxAttempts
       THEN /\ attempts' = attempts + 1
            /\ IF procRunning
                 THEN UNCHANGED <<procRunning, procAdds, autoAddAfterDefaulted, autoAddAfterUserOff>>
                 ELSE /\ procRunning' = TRUE /\ procAdds' = TRUE
                      /\ autoAddAfterDefaulted' = (autoAddAfterDefaulted \/ defaulted)
                      /\ autoAddAfterUserOff' = (autoAddAfterUserOff \/ userTurnedOff)
            /\ timerArmed' = TRUE
            /\ UNCHANGED <<defaulted, defaultedWrittenDuringScript>>
       ELSE /\ attempts' = attempts + 1
            /\ timerArmed' = FALSE
            /\ UNCHANGED <<procRunning, procAdds, defaulted,
                           defaultedWrittenDuringScript, autoAddAfterDefaulted, autoAddAfterUserOff>>
  /\ UNCHANGED <<fileHasWidget, barHasWidget, reloadPending, userTurnedOff>>

ProcExits ==
  /\ procRunning
  /\ procRunning' = FALSE
  /\ fileHasWidget' = procAdds
  /\ reloadPending' = TRUE
  /\ UNCHANGED <<procAdds, barHasWidget, defaulted, attempts, timerArmed,
                 defaultedWrittenDuringScript, autoAddAfterDefaulted, autoAddAfterUserOff, userTurnedOff>>

Reload ==
  /\ reloadPending
  /\ barHasWidget' = fileHasWidget
  /\ reloadPending' = FALSE
  /\ UNCHANGED <<procRunning, procAdds, fileHasWidget, defaulted, attempts, timerArmed,
                 defaultedWrittenDuringScript, autoAddAfterDefaulted, autoAddAfterUserOff, userTurnedOff>>

UserSetsBarIcon(on) ==
  /\ ~procRunning
  /\ procRunning' = TRUE
  /\ procAdds' = on
  /\ userTurnedOff' = ~on
  /\ UNCHANGED <<fileHasWidget, barHasWidget, reloadPending, defaulted, attempts, timerArmed,
                 defaultedWrittenDuringScript, autoAddAfterDefaulted, autoAddAfterUserOff>>

PluginRestarts ==
  /\ ~procRunning
  /\ ~timerArmed
  /\ timerArmed' = TRUE
  /\ attempts' = 0
  /\ barHasWidget' = fileHasWidget
  /\ reloadPending' = FALSE
  /\ UNCHANGED <<procRunning, procAdds, fileHasWidget, defaulted,
                 defaultedWrittenDuringScript, autoAddAfterDefaulted, autoAddAfterUserOff, userTurnedOff>>

Next == PluginRestarts \/ TimerFires \/ ProcExits \/ Reload \/ \E on \in BOOLEAN : UserSetsBarIcon(on)

Spec == Init /\ [][Next]_vars

TypeOK == attempts \in 0..(MaxAttempts + 1)

DefaultedNeverWrittenWhileBarIconScriptRuns == ~defaultedWrittenDuringScript

NoAutoAddOnceDefaulted == ~autoAddAfterDefaulted

NoAutoAddAfterUserTurnedOff == ~autoAddAfterUserOff
====
