## :Author: Edwin (Ikuyu) Jonkvorst
## :Version: 0.1.1
##
## Read-eval-print loop for the life plan api
## ==========================================
##
## Key bindings for the used command line editor can be found at https://github.com/jangko/nim-noise.
## Compile with -d:esc_exit_editing, or: --define:esc_exit_editing

import lifeplan # the life plan api
import noise # nim implementation of the linenoise command line editor (https://github.com/jangko/nim-noise)
from os import fileExists, getHomeDir, joinPath
from strutils import find, toLower, removePrefix, removeSuffix, strip,
      splitWhitespace, isDigit
from terminal import eraseScreen, setCursorPos
from parseutils import parseInt

type
   AnsiColors = enum
      ## Ansi color codes. Not all the colors are used.
      Reset = "\e[0;0m",    # default
      Black = "\e[0;30m",   # 30 = normal; 90 = bright
      Red = "\e[0;31m",     # 31 = normal; 91 = bright
      Green = "\e[0;32m",   # 32 = normal; 92 = bright
      Yellow = "\e[0;33m",  # 33 = normal; 93 = bright
      Blue = "\e[0;34m",    # 34 = normal; 94 = bright
      Magenta = "\e[0;35m", # 35 = normal; 95 = bright
      Cyan = "\e[0;36m",    # 36 = normal; 96 = bright
      White = "\e[0;37m"    # 37 = normal; 97 = bright
   Command {.pure.} = enum
      ## Commands. Possible values: None, Add, Show, Update, Remove, Help, Clear, Erase, ExitSave, ExitNoSave and Unknown.
      None, # default
      Add,
      Show,
      Update,
      Remove,
      Help,
      Clear,
      Erase,
      ExitSave,
      ExitNoSave,
      Unknown,
      Ignore
   Item {.pure.} = enum
      ## Items. Possible values: None, Goal, Action, Agreement, Alert, Result, All, Unknown.
      None, # default
      Goal,
      Action,
      Agreement,
      Alert,
      Result,
      All,
      Unknown,
      Ignore

const
   DEFAULT_LIFEPLAN_FILENAME* = "lipla.dat"
   DEFAULT_HISTORY_FILENAME* = "lipla.his"
   AUTOCOMPLETION_COMMANDS = [
      "add",
      "show",
      "update",
      "remove",
      "goal",
      "goals",
      "action",
      "acitons",
      "agreement",
      "agreements",
      "alert",
      "alerts",
      "result",
      "results",
      "exit",
      "exit!",
      "help",
      "clear",
      "erase"
   ]
   ERROR_MESSAGES = [
      "Incorrect number/type of argument(s)",                  # 0 (unused)
      "Maximum number of allowed goals is 7",                  # 1
      "Maximum number of allowed actions is 7",                # 2
      "Maximum number of allowed agreements is 7",             # 3
      "Maximum number of allowed alerts is 7",                 # 4
      "Maximum number of allowed results is 7",                # 5
      "Not enough indexes. Use more",                          # 6 (unused)
      "Too many indexes. Use none",                            # 7
      "Too many indexes. Use less",                            # 8
      "Nothing to add. Use " & $Yellow & "help" & $Reset &
      " for a list of commands",                               # 9
      "Nothing to show. Use " & $Yellow & "help" & $Reset &
      " for a list of commands",                               # 10
      "Nothing to update. Use " & $Yellow & "help" & $Reset &
      " for a list of commands",                               # 11
      "Nothing to remove. Use " & $Yellow & "help" & $Reset &
      " for a list of commands",                               # 12
      "Incorrect or no number",                                # 13 (unused)
      "Unknown command. Use " & $Yellow & "help" & $Reset &
      " for a list of commands"                                # 14 (unused)
   ]
   HELP = [
      "==================================================================================",
      "Documented commands (type " & $Yellow & "help " & $Reset &
      "<command> for more information:)",
      "==================================================================================",
      "show, s      add goal        show goals        update goal        remove goal",
      "help, h, ?   add action      show actions      udpate action      remove action",
      "exit, x      add agreement   show agreements   update agreement   remove agreement",
      "exit!, x!    add alert       show alerts       update alert       remove alert",
      "clear, c     add result      show results      update result      remove result",
      "erase, e",
      "",
      "Undocumented commands:",
      "==================================================================================",
      "none@the moment"
   ]

proc errorMessage*(message: string) =
   ## Prints an (error) message to the screen prefixed by the word error printed in red.
   echo($Red & "error " & $Reset & message)

proc unQuote(line: string): string =
   ## Removes quotes (' and ") from a string and strips its leading/trailing whitespaces.
   result = line
   result.removePrefix({'\'', '\"'})
   result.removeSuffix({'\'', '\"'})
   result = result.strip()

proc parse(idDescriptionString: string): (seq[int], string) {.
      raises: ValueError.} =
   ## Parses a string containing a possible id and/or description.
   ## Returns the actual id and/or description as a tuple.
   ## The id and/or description is empty (@[], "") if no id/description found.
   ## The id is a sequence of integers which refer to the actual goal/action/agreement/alert and/or result indexes, so every integer is one less than the actual number(s) as typed in by the user.
   ## 0 becomes -1, -1 becomes -2, etc.
   ## Raises an exception if an id number is negative or a zero; lipla id's can't be negative, nor do they start from zero.
   var
      id: seq[int] # will hold the id
      description = idDescriptionString.strip() # will hold the description
      prefix: string # will hold the part that needs to be removed from the description variable in order to get the actual description
      numberAsString: string
      seperators = {' ', '.', '#', ',', '/', '|', ';',
            ':'}   # but not(!) '-' since this is the minus symbol
   for index, character in description: # get the id from the description variable
      if character.isDigit(): # if character is a positive number (zero included)
         numberAsString.add(character)
         if index == description.len - 1:
            var number: int
            discard parseInt($numberAsString, number, 0)
            dec(number)
            id.add(number)
            prefix.add(numberAsString)
      elif character == '-': # if character is the minus symbol
         if not numberAsString.contains('-'):
            numberAsString.add(character)
         else:
            prefix.add(character)
      elif seperators.contains(character):
         if numberAsString != "":
            var number: int
            discard parseInt($numberAsString, number, 0)
            dec(number)
            id.add(number)
            prefix.add(numberAsString)
         prefix.add(character)
         numberAsString = ""
      else:
         break # we've reached the actual description
   for index in id:
      if index == -1: # meaning 0
         raise newException(ValueError, "zero id")
      elif index < -1: # meaning less than 0
         raise newException(ValueError, "negative id")
   description.removePrefix(prefix)
   description = description.unQuote()
   (id, description)

method show(lifePlan: LifePlan, item: Item) {.base.} =
   ## Prints one or more items from a life plan.
   var
      command: string
   echo("=====================")
   echo("Item(Id): Description")
   echo("=====================")
   for goIndex, goal in lifePlan.goals:
      let goNr = $Cyan & $(goIndex + 1) & $Reset
      if item == Item.All or item == Item.Goal:
         echo($Cyan & "Goal" & $Reset & "(" & goNr & "): " & goal.description)
      for acIndex, action in goal.actions:
         let acNr = $Yellow & $(acIndex + 1) & $Reset
         if item == Item.All or item == Item.Action:
            if item == All:
               command = " Action"
            else:
               command = "Action"
            echo($Yellow & command & $Reset & "(" & goNr & "." & acNr & "): " &
                  action.description)
         for agIndex, agreement in action.agreements:
            let agNr = $Green & $(agIndex + 1) & $Reset
            if item == Item.All or item == Item.Agreement:
               if item == Item.All:
                  command = "  Agreement"
               else:
                  command = "Agreement"
               echo($Green & command & $Reset & "(" & goNr & "." & acNr & "." &
                     agNr & "): " & agreement.description)
            for alIndex, alert in agreement.alerts:
               let alNr = $Red & $(alIndex + 1) & $Reset
               if item == All or item == Item.Alert:
                  if item == Item.All:
                     command = "   Alert"
                  else:
                     command = "Alert"
                  echo($Red & command & $Reset & "(" & goNr & "." & acNr & "." &
                        agNr & "." & alNr & "): " & alert.description)
      for reIndex, result in goal.results:
         let reNr = $Blue & $(reIndex + 1) & $Reset
         if item == Item.All or item == Item.Result:
            if item == All:
               command = " Result"
            else:
               command = "Result"
            echo($Blue & command & $Reset & "(" & goNr & "." & reNr & "): " &
                  result.description)

method addGoal(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Adds a goal to a life plan.
   try:
      let (id, description) = parse(remainder)
      if id.len >= 1:
         errorMessage(ERROR_MESSAGES[7])
      elif lifePlan.goals.len < 7:
         if id.len != 0:
            if id[0] < 0:
               errorMessage(ERROR_MESSAGES[9]) # nothing to add
         elif description != "":
            lifePlan.goals.add(newGoal(description.unQuote()))
         else:
            while true:
               noise.setPrompt("Description (ESC to abort): ")
               let ok = noise.readLine()
               if not ok:
                  quit()
               if noise.getKeyType == ktEsc:
                  break
               else:
                  let description = noise.getLine().unQuote()
                  if description != "":
                     lifePlan.goals.add(newGoal(description))
                     break
         noise.setPrompt("Lipla> ")
      else:
         errorMessage(ERROR_MESSAGES[1]) # maximum number of allowed goals is 7
   except:
      errorMessage(getCurrentExceptionMsg())

method addAction(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Adds an action to a goal.
   try:
      let (id, description) = parse(remainder)
      if id.len > 1:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 1:
         if id[0] < lifeplan.goals.len and id[0] >=
               0: # error when adding an action to a non existent goal number
            if lifePlan.goals[id[0]].actions.len < 7:
               if id[0] < 0:
                  errorMessage(ERROR_MESSAGES[9]) # nothing to add
               elif description != "":
                  lifePlan.goals[id[0]].actions.add(newAction(
                        description.unQuote()))
               else:
                  noise.setPrompt("Description (ESC to abort): ")
                  while true:
                     let ok = noise.readLine()
                     if not ok:
                        quit()
                     if noise.getKeyType == ktEsc:
                        break
                     else:
                        let description = noise.getLine().unQuote()
                        if description != "":
                           lifePlan.goals[id[0]].actions.add(newAction(description))
                           break
               noise.setPrompt("Lipla> ")
            else:
               errorMessage(ERROR_MESSAGES[2])
         else:
            errorMessage(ERROR_MESSAGES[9])
      else:
         errorMessage("Usage:" & $Yellow & " add action " & $Reset & "<goal number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method addAgreement(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Adds an agreement to an action.
   try:
      let (id, description) = parse(remainder)
      if id.len > 2:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 2:
         if id[0] < lifeplan.goals.len and id[0] >=
               0: # error when adding an action to a non existent goal number
            if id[1] < lifeplan.goals[id[0]].actions.len and id[1] >=
                  0: # error when adding an agreement to a non existent action number
               if lifePlan.goals[id[0]].actions[id[1]].agreements.len < 7:
                  if id[0] < 0 or id[1] < 0:
                     errorMessage(ERROR_MESSAGES[9]) # nothing to add
                  elif description != "":
                     lifePlan.goals[id[0]].actions[id[1]].agreements.add(
                           newAgreement(description.unQuote()))
                  else:
                     noise.setPrompt("Description (ESC to abort): ")
                     while true:
                        let ok = noise.readLine()
                        if not ok:
                           quit()
                        if noise.getKeyType == ktEsc:
                           break
                        else:
                           let description = noise.getLine().unQuote()
                           if description != "":
                              lifePlan.goals[id[0]].actions[id[
                                    1]].agreements.add(newAgreement(description))
                              break
                  noise.setPrompt("Lipla> ")
               else:
                  errorMessage(ERROR_MESSAGES[3])
            else:
               errorMessage(ERROR_MESSAGES[9])
         else:
            errorMessage(ERROR_MESSAGES[9])
      else:
         errorMessage("Usage:" & $Yellow & " add agreement " & $Reset & "<goal number> <action number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method addAlert(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Adds an alert to an agreement
   try:
      let (id, description) = parse(remainder)
      if id.len > 3:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 3:
         if id[0] < lifeplan.goals.len and id[0] >=
               0: # error when adding an action to a non existent goal number
            if id[1] < lifeplan.goals[id[0]].actions.len and id[1] >=
                  0: # error when adding an agreement to a non existent action number
               if id[2] < lifeplan.goals[id[0]].actions[id[
                     1]].agreements.len and id[2] >=
                     0: # error when adding an alert to a non existent agreement number
                  if lifePlan.goals[id[0]].actions[id[1]].agreements[id[
                        2]].alerts.len < 7:
                     if id[0] < 0 or id[1] < 0 or id[2] < 0:
                        errorMessage(ERROR_MESSAGES[9]) # nothing to add
                     elif description != "":
                        lifePlan.goals[id[0]].actions[id[1]].agreements[id[
                              2]].alerts.add(newAlert(description.unQuote()))
                     else:
                        noise.setPrompt("Description (ESC to abort): ")
                        while true:
                           let ok = noise.readLine()
                           if not ok:
                              quit()
                           if noise.getKeyType == ktEsc:
                              break
                           else:
                              let description = noise.getLine().unQuote()
                              if description != "":
                                 lifePlan.goals[id[0]].actions[id[
                                       1]].agreements[id[2]].alerts.add(
                                             newAlert(description))
                                 break
                     noise.setPrompt("Lipla> ")
                  else:
                     errorMessage(ERROR_MESSAGES[4])
               else:
                  errorMessage(ERROR_MESSAGES[9])
            else:
               errorMessage(ERROR_MESSAGES[9])
         else:
            errorMessage(ERROR_MESSAGES[9])
      else:
         errorMessage("Usage:" & $Yellow & " add alert " & $Reset & "<goal number> <action number> <agreement number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method addResult(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Add a result to a goal.
   try:
      let (id, description) = parse(remainder)
      if id.len > 1:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 1:
         if id[0] < lifeplan.goals.len and id[0] >=
               0: # error when adding an action to a non existent goal number
            if lifePlan.goals[id[0]].results.len < 7:
               if id[0] < 0:
                  errorMessage(ERROR_MESSAGES[9]) # nothing to add
               elif description != "":
                  lifePlan.goals[id[0]].results.add(newResult(
                        description.unQuote()))
               else:
                  noise.setPrompt("Description (ESC to abort): ")
                  while true:
                     let ok = noise.readLine()
                     if not ok:
                        quit()
                     if noise.getKeyType == ktEsc:
                        break
                     else:
                        let description = noise.getLine().unQuote()
                        if description != "":
                           lifePlan.goals[id[0]].results.add(newResult(description))
                           break
               noise.setPrompt("Lipla> ")
            else:
               errorMessage(ERROR_MESSAGES[5])
         else:
            errorMessage(ERROR_MESSAGES[9])
      else:
         errorMessage("Usage:" & $Yellow & " add result " & $Reset & "<goal number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method showGoal(lifePlan: LifePlan) {.base.} =
   ## Prints all goals from a life plan (if are there any).
   if lifePlan.goals == @[]:
      errorMessage(ERROR_MESSAGES[10])
   else:
      lifePlan.show(Item.Goal)

method showAction(lifePlan: LifePlan) {.base.} =
   ## Prints all actions from a life plan (if are there any).
   var
      found = false
   for goal in lifePlan.goals:
      if goal.actions != @[]:
         found = true
         break
   if found:
      show(lifePlan, Item.Action)
   else:
      errorMessage(ERROR_MESSAGES[10])

method showAgreement(lifePlan: LifePlan) {.base.} =
   ## Prints all agreements from a life plan (if are there any).
   var
      found = false
   for goal in lifePlan.goals:
      for action in goal.actions:
         if action.agreements != @[]:
            found = true
            break
   if found:
      show(lifePlan, Item.Agreement)
   else:
      errorMessage(ERROR_MESSAGES[10])

method showAlert(lifePlan: LifePlan) {.base.} =
   ## Print all alerts from a life plan (if are there any).
   var
      found = false
   for goal in lifePlan.goals:
      for action in goal.actions:
         for agreement in action.agreements:
            if agreement.alerts != @[]:
               found = true
               break
   if found:
      show(lifePlan, Item.Alert)
   else:
      errorMessage(ERROR_MESSAGES[10])

method showResult(lifePlan: LifePlan) {.base.} =
   ## Prints all results from a life plan (if are there any).
   var
      found = false
   for goal in lifePlan.goals:
      if goal.results != @[]:
         found = true
         break
   if found:
      show(lifePlan, Item.Result)
   else:
      errorMessage(ERROR_MESSAGES[10])

method updateGoal(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Updates a goal from a life plan.
   try:
      let (id, description) = parse(remainder)
      if id.len > 1:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 1:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if description != "":
               lifePlan.goals[id[0]].description = description.unQuote()
            else:
               while true:
                  noise.setPrompt("Description (ESC to abort): ")
                  noise.preloadBuffer(lifePlan.goals[id[0]].description)
                  let ok = noise.readLine()
                  if not ok:
                     quit()
                  if noise.getKeyType == ktEsc:
                     break
                  else:
                     let description = noise.getLine().unQuote()
                     if description != "":
                        lifePlan.goals[id[0]].description = description
                        break
               noise.setPrompt("Lipla> ")
         else:
            errorMessage(ERROR_MESSAGES[11])
      else:
         errorMessage("Usage:" & $Yellow & " update goal " & $Reset & "<goal number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method updateAction(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Updates an action from a goal.
   try:
      let (id, description) = parse(remainder)
      if id.len > 2:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 2:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if id[1] < lifePlan.goals[id[0]].actions.len and id[1] >= 0:
               if description != "":
                  lifePlan.goals[id[0]].actions[id[
                        1]].description = description.unQuote()
               else:
                  while true:
                     noise.setPrompt("Description (ESC to abort): ")
                     noise.preloadBuffer(lifePlan.goals[id[0]].actions[id[
                           1]].description)
                     let ok = noise.readLine()
                     if not ok:
                        quit()
                     if noise.getKeyType == ktEsc:
                        break
                     else:
                        let description = noise.getLine().unQuote()
                        if description != "":
                           lifePlan.goals[id[0]].actions[id[
                                 1]].description = description
                           break
                  noise.setPrompt("Lipla> ")
            else:
               errorMessage(ERROR_MESSAGES[11])
         else:
            errorMessage(ERROR_MESSAGES[11])
      else:
         errorMessage("Usage:" & $Yellow & " update action " & $Reset & "<goal number> <action number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method updateAgreement(lifePlan: LifePlan, noise: var Noise,
      remainder: string) {.base.} =
   ## Updates an agreement from an action.
   try:
      let (id, description) = parse(remainder)
      if id.len > 3:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 3:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if id[1] < lifePlan.goals[id[0]].actions.len and id[1] >= 0:
               if id[2] < lifePlan.goals[id[0]].actions[id[
                     1]].agreements.len and id[2] >= 0:
                  if description != "":
                     lifePlan.goals[id[0]].actions[id[1]].agreements[id[
                           2]].description = description.unQuote()
                  else:
                     while true:
                        noise.setPrompt("Description (ESC to abort): ")
                        noise.preloadBuffer(lifePlan.goals[id[0]].actions[id[
                              1]].agreements[id[2]].description)
                        let ok = noise.readLine()
                        if not ok:
                           quit()
                        if noise.getKeyType == ktEsc:
                           break
                        else:
                           let description = noise.getLine().unQuote()
                           if description != "":
                              lifePlan.goals[id[0]].actions[id[1]].agreements[
                                    id[2]].description = description
                              break
                     noise.setPrompt("Lipla> ")
               else:
                  errorMessage(ERROR_MESSAGES[11])
            else:
               errorMessage(ERROR_MESSAGES[11])
         else:
            errorMessage(ERROR_MESSAGES[11])
      else:
         errorMessage("Usage:" & $Yellow & " update agreement " & $Reset & "<goal number> <action number> <agreement number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method updateAlert(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Updates an alert from a agreement.
   try:
      let (id, description) = parse(remainder)
      if id.len > 4:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 4:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if id[1] < lifePlan.goals[id[0]].actions.len and id[1] >= 0:
               if id[2] < lifePlan.goals[id[0]].actions[id[
                     1]].agreements.len and id[2] >= 0:
                  if id[3] < lifePlan.goals[id[0]].actions[id[1]].agreements[id[
                        2]].alerts.len and id[3] >= 0:
                     if description != "":
                        lifePlan.goals[id[0]].actions[id[1]].agreements[id[
                              2]].alerts[id[
                              3]].description = description.unQuote()
                     else:
                        while true:
                           noise.setPrompt("Description (ESC to abort): ")
                           noise.preloadBuffer(lifePlan.goals[id[0]].actions[id[
                                 1]].agreements[id[2]].alerts[id[
                                 3]].description)
                           let ok = noise.readLine()
                           if not ok:
                              quit()
                           if noise.getKeyType == ktEsc:
                              break
                           else:
                              let description = noise.getLine().unQuote()
                              if description != "":
                                 lifePlan.goals[id[0]].actions[id[
                                       1]].agreements[id[2]].alerts[id[
                                       3]].description = description
                                 break
                        noise.setPrompt("Lipla> ")
                  else:
                     errorMessage(ERROR_MESSAGES[11])
               else:
                  errorMessage(ERROR_MESSAGES[11])
            else:
               errorMessage(ERROR_MESSAGES[11])
         else:
            errorMessage(ERROR_MESSAGES[11])
      else:
         errorMessage("Usage:" & $Yellow & " update alert " & $Reset & "<goal number> <action number> <agreement number> <alert number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method updateResult(lifePlan: LifePlan, noise: var Noise, remainder: string) {.base.} =
   ## Updates a result from a goal.
   try:
      let (id, description) = parse(remainder)
      if id.len > 2:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 2:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if id[1] < lifePlan.goals[id[0]].results.len and id[1] >= 0:
               if description != "":
                  lifePlan.goals[id[0]].results[id[
                        1]].description = description.unQuote()
               else:
                  while true:
                     noise.setPrompt("Description (ESC to abort): ")
                     noise.preloadBuffer(lifePlan.goals[id[0]].results[id[
                           1]].description)
                     let ok = noise.readLine()
                     if not ok:
                        quit()
                     if noise.getKeyType == ktEsc:
                        break
                     else:
                        let description = noise.getLine().unQuote()
                        if description != "":
                           lifePlan.goals[id[0]].results[id[
                                 1]].description = description
                           break
                  noise.setPrompt("Lipla> ")
            else:
               errorMessage(ERROR_MESSAGES[11])
         else:
            errorMessage(ERROR_MESSAGES[11])
      else:
         errorMessage("Usage:" & $Yellow & " update result " & $Reset & "<goal number> <result number> [description]")
   except:
      errorMessage(getCurrentExceptionMsg())

method removeGoal(lifePlan: LifePlan, remainder: string) {.base.} =
   ## Removes a goal from a life plan.
   try:
      let (id, _) = parse(remainder)
      if id.len > 1:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 1:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            lifePlan.goals.delete(id[0])
         else:
            errorMessage(ERROR_MESSAGES[12])
      else:
         errorMessage("Usage:" & $Yellow & " remove goal " & $Reset & "<goal number>")
   except:
      errorMessage(getCurrentExceptionMsg())

method removeAction(lifePlan: LifePlan, remainder: string) {.base.} =
   ## Removes an action from a goal.
   try:
      let (id, _) = parse(remainder)
      if id.len > 2:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 2:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if id[1] < lifePlan.goals[id[0]].actions.len and id[1] >= 0:
               lifePlan.goals[id[0]].actions.delete(id[1])
            else:
               errorMessage(ERROR_MESSAGES[12])
         else:
            errorMessage(ERROR_MESSAGES[12])
      else:
         errorMessage("Usage:" & $Yellow & " remove action " & $Reset & "<goal number> <action number>")
   except:
      errorMessage(getCurrentExceptionMsg())

method removeAgreement(lifePlan: LifePlan, remainder: string) {.base.} =
   ## Removes an agreement from an action.
   try:
      let (id, _) = parse(remainder)
      if id.len > 3:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 3:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if id[1] < lifePlan.goals[id[0]].actions.len and id[1] >= 0:
               if id[2] < lifePlan.goals[id[0]].actions[id[1]]
               .agreements.len and id[2] >= 0:
                  lifePlan.goals[id[0]].actions[id[1]].agreements.delete(id[2])
               else:
                  errorMessage(ERROR_MESSAGES[12])
            else:
               errorMessage(ERROR_MESSAGES[12])
         else:
            errorMessage(ERROR_MESSAGES[12])
      else:
         errorMessage("Usage:" & $Yellow & " remove agreement " & $Reset & "<goal number> <action number> <agreement number>")
   except:
      errorMessage(getCurrentExceptionMsg())

method removeAlert(lifePlan: LifePlan, remainder: string) {.base.} =
   ## Removes an alert from an agreement.
   try:
      let (id, _) = parse(remainder)
      if id.len > 4:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 4:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if id[1] < lifePlan.goals[id[0]].actions.len and id[1] >= 0:
               if id[2] < lifePlan.goals[id[0]].actions[id[1]]
               .agreements.len and id[2] >= 0:
                  if id[3] < lifePlan.goals[id[0]].actions[id[1]].agreements[id[2]]
                  .alerts.len and id[3] >= 0:
                     lifePlan.goals[id[0]].actions[id[1]].agreements[id[2]]
                     .alerts.delete(id[3])
                  else:
                     errorMessage(ERROR_MESSAGES[12])
               else:
                  errorMessage(ERROR_MESSAGES[12])
            else:
               errorMessage(ERROR_MESSAGES[12])
         else:
            errorMessage(ERROR_MESSAGES[12])
      else:
         errorMessage("Usage:" & $Yellow & " remove alert " & $Reset & "<goal number> <action number> <agreement number> <alert number>")
   except:
      errorMessage(getCurrentExceptionMsg())

method removeResult(lifePlan: LifePlan, remainder: string) {.base.} =
   ## Removes a result form a goal.
   try:
      let (id, _) = parse(remainder)
      if id.len > 2:
         errorMessage(ERROR_MESSAGES[8])
      elif id.len == 2:
         if id[0] < lifePlan.goals.len and id[0] >= 0:
            if id[1] < lifePlan.goals[id[0]].results.len and id[1] >= 0:
               lifePlan.goals[id[0]].results.delete(id[1])
            else:
               errorMessage(ERROR_MESSAGES[12])
         else:
            errorMessage(ERROR_MESSAGES[12])
      else:
         errorMessage("Usage:" & $Yellow & " remove result " & $Reset & "<goal number> <result number>")
   except:
      errorMessage(getCurrentExceptionMsg())
proc completionHook(noise: var Noise, text: string): int =
   ## Adds a list of commands to a Noise linereader type, used for autocompletion.
   for command in AUTOCOMPLETION_COMMANDS:
      if command.find(text) != -1:
         noise.addCompletion command

proc repl*(historyFilename: string, lifePlanFilename: string) =
   ## Read-eval-print for a life plan.
   var
      lifePlan = newLifePlan()
      noise = Noise.init()
   # ============
   # LOAD HISTORY
   # ============
   if fileExists(historyFilename): # a non-existent file is created on exit
      try:
         discard noise.historyLoad(historyFilename)
      except:
         errorMessage("Unable to load " & $Yellow & historyFilename & $Reset)
         quit()
   # =============
   # LOAD LIFEPLAN
   # =============
   if fileExists(lifePlanFilename):
      try:
         lifePlan = load(lifePlanFilename)
      except:
         errorMessage("Unable to load " & $Yellow & lifePlanFilename & $Reset)
         quit()
   else:
      while true:
         stdout.write("Create and use " & $Yellow & lifePlanFilename & $Reset & " as database (Y/n)? ")
         let answer = stdin.readLine().toLower()
         if answer == "n":
            quit()
         elif answer == "y" or answer == "":
            break
         else:
            continue
   # ===============
   # WELCOME MESSAGE
   # ===============
   if lifePlanFilename == joinPath(getHomeDir(), DEFAULT_LIFEPLAN_FILENAME) and
         lifePlan.isEmpty():
      echo("Welcome to Lipla! Use " & $Yellow & "help" & $Reset & " for a list of commands")
   else:
      echo("Welcome to Lipla! Using " & $Yellow & lifePlanFilename & $Reset & " as database")
   # ===========================
   # PROMPT/AUTOCOMPLETION WORDS
   # ===========================
   noise.setPrompt("Lipla> ")
   noise.setCompletionHook(completionHook)
   # =========
   # REPL LOOP
   # =========
   while true:
      # this readLine() comes from the noise library, not the standard library
      let ok = noise.readLine()
      if not ok:
         # the user hit CRTL-C or CTRL-D
         return
      # remove leading/trailing spaces from the input
      var
         input = noise.getLine().strip() # split the input into words without surrounding whitespaces.
         words = input.splitWhitespace(-1)
      # =========
      # INTERPRET
      # =========
      # skip if the input is
      if input.len > 0:
         var
            # there can only be two commands
            firstCommand, secondCommand: Command # default = Command.None
                                                 # one item
            item: Item                           # default = Item.None
                          # and a remainder; the remainder is the input minus the command(s)/item
                          # for now, the remainder contains the whole input
            remainder = input
            firstWord, secondWord, thirdWord: string
            skip = false
         # ======
         # FILTER
         # ======
         # if the first OR the second word is show AND the first word OR the second word is 'goals', 'actions', 'agreements', 'alerts' or 'results'
         firstWord = words[0].toLower()
         if words.len >= 2:
            secondWord = words[1].toLower()
            if firstWord == "s" or firstWord == "sh" or firstWord == "show":
               firstCommand = Command.Show
            elif secondWord == "s" or secondWord == "sh" or secondWord == "show":
               firstCommand = Command.Show
            if firstCommand == Command.Show:
               if firstWord == "goals" or secondWord == "goals":
                  item = Item.Goal
                  skip = true
               elif firstWord == "actions" or secondWord == "actions":
                  item = Item.Action
                  skip = true
               elif firstWord == "agreements" or secondWord == "agreements":
                  item = Item.Agreement
                  skip = true
               elif firstWord == "alerts" or secondWord == "alerts":
                  item = Item.Alert
                  skip = true
               elif firstWord == "results" or secondWord == "results":
                  item = Item.Result
                  skip = true
         if words.len >= 3:
            thirdWord = words[2].toLower()
            # if the first word is '?', 'h', 'he' or 'help'
            if firstWord == "?" or firstWord == "h" or firstWord == "he" or
                  firstWord == "help":
               firstCommand = Command.Help
               if secondWord == "s" or secondWord == "sh" or secondWord == "show":
                  secondCommand = Command.Show
               elif thirdWord == "s" or thirdWord == "sh" or thirdWord == "show":
                  secondCommand = Command.Show
               if secondCommand == Command.Show:
                  if secondWord == "goals" or thirdWord == "goals":
                     item = Item.Goal
                     skip = true
                  elif thirdWord == "goals":
                     item = Item.Goal
                     skip = true
                  elif secondWord == "actions" or thirdWord == "actions":
                     item = Item.Action
                     skip = true
                  elif secondWord == "agreements" or thirdWord == "agreements":
                     item = Item.Agreement
                     skip = true
                  elif secondWord == "alerts" or thirdWord == "alerts":
                     item = Item.Alert
                     skip = true
                  elif secondWord == "results" or thirdWord == "results":
                     item = Item.Result
                     skip = true
         # ==========
         # FIRST WORD
         # ==========
         case firstWord:
            of "x", "ex", "exit":
               firstCommand = Command.ExitSave
            of "x!", "ex!", "exit!":
               firstCommand = Command.ExitNoSave
            of "c", "cl", "clear":
               firstCommand = Command.Clear
            of "e", "er", "erase":
               firstCommand = Command.Erase
            of "a", "ad", "add":
               firstCommand = Command.Add
            of "s", "sh", "show":
               firstCommand = Command.Show
               if words.len == 1:
                  item = Item.All
            of "u", "up", "update":
               firstCommand = Command.Update
            of "remove":
               firstCommand = Command.Remove
            of "h", "he", "?", "help":
               firstCommand = Command.Help
            else:
               firstCommand = Command.Unknown
               case firstWord:
               of "go", "goal":
                  if words.len >= 2 and secondWord != "s" or secondWord !=
                        "sh" or secondWord != "show":
                     item = Item.Goal
                     skip = true
                  else:
                     item = Item.Unknown
               of "ac", "action":
                  if words.len >= 2 and secondWord != "s" or secondWord !=
                        "sh" or secondWord != "show":
                     item = Item.Action
                     skip = true
                  else:
                     item = Item.Unknown
               of "ag", "agreement":
                  if words.len >= 2 and secondWord != "s" or secondWord !=
                        "sh" or secondWord != "show":
                     item = Item.Agreement
                     skip = true
                  else:
                     item = Item.Unknown
               of "al", "alert":
                  if words.len >= 2 and secondWord != "s" or secondWord !=
                        "sh" or secondWord != "show":
                     item = Item.Alert
                     skip = true
                  else:
                     item = Item.Unknown
               of "result":
                  if words.len >= 2 and secondWord != "s" or secondWord !=
                        "sh" or secondWord != "show":
                     item = Item.Result
                     skip = true
                  else:
                     item = Item.Unknown
               else:
                  if not skip:
                     item = Item.Unknown
         # ===========
         # SECOND WORD
         # ===========
         if words.len >= 2:
            case secondWord:
            of "x", "ex", "exit":
               secondCommand = Command.ExitSave
            of "x!", "ex!", "exit!":
               secondCommand = Command.ExitNoSave
            of "c", "cl", "clear":
               secondCommand = Command.Clear
            of "e", "er", "erase":
               secondCommand = Command.Erase
            of "a", "ad", "add":
               if firstCommand != Command.Help:
                  firstCommand = Command.Add
               else:
                  secondCommand = Command.Add
            of "s", "sh", "show":
               if firstCommand != Command.Help:
                  firstCommand = Command.Show
               else:
                  secondCommand = Command.Show
               case firstWord:
               of "goal", "action", "agreement", "alert", "result":
                  item = Item.Unknown
               else:
                  discard
               if firstCommand == Command.Help and words.len == 2:
                  item = Item.All
            of "u", "up", "update":
               if firstCommand != Command.Help:
                  firstCommand = Command.Update
               else:
                  secondCommand = Command.Update
            of "remove":
               if firstCommand != Command.Help:
                  firstCommand = Command.Remove
               else:
                  secondCommand = Command.Remove
            of "h", "he", "?", "help":
               secondCommand = Command.Help
            else:
               case secondWord:
               of "go", "goal":
                  if firstCommand != Command.Show:
                     item = Item.Goal
                  elif secondWord == "go":
                     item = Item.Goal
                  else:
                     item = Item.Unknown
               of "ac", "action":
                  if firstCommand != Command.Show:
                     item = Item.Action
                  elif secondWord == "ac":
                     item = Item.Action
                  else:
                     item = Item.Unknown
               of "ag", "agreement":
                  if firstCommand != Command.Show:
                     item = Item.Agreement
                  elif secondWord == "ag":
                     item = Item.Agreement
                  else:
                     item = Item.Unknown
               of "al", "alert":
                  if firstCommand != Command.Show:
                     item = Item.Alert
                  elif secondWord == "al":
                     item = Item.Alert
                  else:
                     item = Item.Unknown
               of "result":
                  if firstCommand != Command.Show:
                     item = Item.Result
                  else:
                     item = Item.Unknown
               else:
                  if not skip:
                     if item == Item.None:
                        item = Item.Unknown
            # the combination 're' can have two meanings: 'remove' and 'result'
            if (firstWord == "re" or firstWord == "r") and secondWord == "re" or
                  secondWord == "r":
               firstCommand = Command.Remove
               item = Item.Result
            elif firstWord == "re" or firstWord == "r":
               case secondWord:
               of "go", "goal", "ac", "action", "ag", "agreement", "al",
                     "alert", "result":
                  firstCommand = Command.Remove
               of "a", "ad", "add", "s", "sh", "show", "u", "up", "update", "remove":
                  item = Item.Result
               else:
                  discard
            elif secondWord == "re" or secondWord == "r":
               case firstWord:
               of "go", "goal", "ac", "action", "ag", "agreement", "al",
                     "alert", "result":
                  firstCommand = Command.Remove
               of "a", "ad", "add", "s", "sh", "show", "u", "up", "update", "remove":
                  item = Item.Result
               else:
                  discard
         # ==========
         # THIRD WORD
         # ==========
         if words.len >= 3:
            # if the first word is '?', 'h', 'he' or 'help'
            case thirdWord:
            of "a", "ad", "add":
               secondCommand = Command.Add
            of "s", "sh", "show":
               secondCommand = Command.Show
            of "u", "up", "update":
               secondCommand = Command.Update
            of "remove":
               secondCommand = Command.Remove
            else:
               case thirdWord:
               of "go", "goal":
                  if secondCommand == Command.Show and thirdWord == "goal":
                     discard
                  else:
                     item = Item.Goal
               of "ac", "action":
                  if secondCommand == Command.Show and thirdWord != "action":
                     discard
                  else:
                     item = Item.Action
               of "ag", "agreement":
                  if secondCommand == Command.Show and thirdWord != "agreement":
                     discard
                  else:
                     item = Item.Agreement
               of "al", "alert":
                  if secondCommand == Command.Show and thirdWord != "alert":
                     discard
                  else:
                     item = Item.Alert
               of "result":
                  if secondCommand == Command.Show and thirdWord != "result":
                     discard
                  else:
                     item = Item.Result
               else:
                  if item == Item.None:
                     item = Item.Unknown
            # the combination 're' can have two meanings: 'remove' and 'result'
            if (secondWord == "re" or secondWord == "r") and (thirdWord ==
                  "re" or thirdWord == "r"):
               secondCommand = Command.Remove
               item = Item.Result
            elif secondWord == "re" or secondWord == "r":
               case thirdWord:
               of "go", "goal", "ac", "action", "ag", "agreement", "al",
                     "alert", "result":
                  secondCommand = Command.Remove
               of "a", "ad", "add", "s", "sh", "show", "u", "up", "update", "remove":
                  item = Item.Result
               else:
                  discard
            elif thirdWord == "re" or thirdWord == "r":
               case secondWord:
               of "go", "goal", "ac", "action", "ag", "agreement", "al",
                     "alert", "result":
                  secondCommand = Command.Remove
               of "a", "ad", "add", "s", "sh", "show", "u", "up", "update", "remove":
                  item = Item.Result
               else:
                  discard
         # =============
         # THE REMAINDER
         # =============
         if firstCommand != Command.Unknown:
            # remove the first word from the remainder
            removePrefix(remainder, words[0]) # remove it
            remainder = remainder.strip()
            # in case there is also a second word
            if words.len >= 2:
               if secondCommand != Command.Unknown: # if there is a second command
                  # remove the second word from the remainder
                  removePrefix(remainder, words[1]) # remove it
                  remainder = remainder.strip()
                  # in case there is also a third word
                  if words.len >= 3:
                     # if there's also an item
                     if item == Item.Unknown:
                        # remove the third word from the remainder
                        removePrefix(remainder, words[2]) # remove it
                        remainder = remainder.strip()
         # ====
         # CASE
         # ====
         case firstCommand
         # ====
         # HELP
         # ====
         of Command.Help:
            if words.len >= 2:
               case secondCommand:
               of Command.Show:
                  case item:
                  of Item.Goal:
                     echo("Command " & $Yellow & "show goals" & $Reset & ": show all goals")
                  of Item.Action:
                     echo("Command " & $Yellow & "show actions" & $Reset & ": show all actions")
                  of Item.Agreement:
                     echo("Command " & $Yellow & "show agreements" & $Reset & ": show all agreements")
                  of Item.Alert:
                     echo("Command " & $Yellow & "show alerts" & $Reset & ": show all alerts")
                  of Item.Result:
                     echo("Command " & $Yellow & "show results" & $Reset & ": show all results")
                  of Item.All:
                     echo("Command " & $Yellow & "show" & $Reset & ": show a life plan")
                  else:
                     item = Item.Unknown
               of Command.ExitSave:
                  echo("Command " & $Yellow & "exit" & $Reset & ": save a life plan and exit")
                  item = Item.Ignore
               of Command.ExitNoSave:
                  echo("Command " & $Yellow & "exit!" & $Reset & ": exit without saving a life plan")
                  item = Item.Ignore
               of Command.Clear:
                  echo("Command " & $Yellow & "clear" & $Reset & ": erase the screen")
                  item = Item.Ignore
               of Command.Erase:
                  echo("Command " & $Yellow & "erase" & $Reset & ": clear the history")
                  item = Item.Ignore
               of Command.Help:
                  echo("Command " & $Yellow & "help" & $Reset & ": prints help information")
                  item = Item.Ignore
               of Command.Add:
                  case item:
                  of Item.Goal:
                     echo("Command " & $Yellow & "add goal" & $Reset & ": add a new goal")
                     echo("Usage:" & $Yellow & " add goal " & $Reset & "[description]")
                  of Item.Action:
                     echo("Command " & $Yellow & "add action" & $Reset & ": add an action")
                     echo("Usage:" & $Yellow & " add action " & $Reset & "<goal number> [description]")
                  of Item.Agreement:
                     echo("Command " & $Yellow & "add agreement" & $Reset & ": add an agreement")
                     echo("Usage:" & $Yellow & " add agreement " & $Reset & "<goal number> <action number> [description]")
                  of Item.Alert:
                     echo("Command " & $Yellow & "add alert" & $Reset & ": add an alert")
                     echo("Usage:" & $Yellow & " add alert " & $Reset & "<goal number> <action number> <agreement number> [description]")
                  of Item.Result:
                     echo("Command " & $Yellow & "add result" & $Reset & ": add a result")
                     echo("Usage:" & $Yellow & " add result " & $Reset & "<goal number> <action number> [description]")
                  else:
                     item = Item.Unknown
               of Command.Update:
                  case item:
                  of Item.Goal:
                     echo("Command " & $Yellow & "update goal" & $Reset & ": update a goal")
                     echo("Usage:" & $Yellow & " update goal " & $Reset & "<goal number> [description]")
                  of Item.Action:
                     echo("Command " & $Yellow & "update action" & $Reset & ": update an action")
                     echo("Usage:" & $Yellow & " update action " & $Reset & "<goal number> <action number> [description]")
                  of Item.Agreement:
                     echo("Command " & $Yellow & "update agreement" & $Reset & ": update an agreement")
                     echo("Usage:" & $Yellow & " update agreement " & $Reset & "<goal number> <action number> <agreement number> [description]")
                  of Item.Alert:
                     echo("Command " & $Yellow & "update alert" & $Reset & ": update an alert")
                     echo("Usage:" & $Yellow & " update alert " & $Reset & "<goal number> <action number> <agreement number> <alert number> [description]")
                  of Item.Result:
                     echo("Command " & $Yellow & "update result" & $Reset & ": update a result")
                     echo("Usage:" & $Yellow & " update result " & $Reset & "<goal number> [description]")
                  else:
                     item = Item.Unknown
               of Command.Remove:
                  case item:
                  of Item.Goal:
                     echo("Command " & $Yellow & "remove goal" & $Reset & ": remove a goal")
                     echo("Usage:" & $Yellow & " remove goal " & $Reset & "<goal number>")
                  of Item.Action:
                     echo("Command " & $Yellow & "remove action" & $Reset & ": remove an action")
                     echo("Usage:" & $Yellow & " remove action " & $Reset & "<goal number> <action number>")
                  of Item.Agreement:
                     echo("Command " & $Yellow & "remove agreement" & $Reset & ": remove an agreement")
                     echo("Usage:" & $Yellow & " remove agreement " & $Reset & "<goal number> <action number> <agreement number>")
                  of Item.Alert:
                     echo("Command " & $Yellow & "remove alert" & $Reset & ": remove an alert")
                     echo("Usage:" & $Yellow & " remove alert " & $Reset & "<goal number> <action number> <agreement number> <alert number>")
                  of Item.Result:
                     echo("Command " & $Yellow & "remove result" & $Reset & ": remove a result")
                     echo("Usage:" & $Yellow & " remove result " & $Reset & "<goal number>")
                  else:
                     item = Item.Unknown
               else:
                  item = Item.Unknown
            else:
               for line in HELP:
                  echo line
                  item = Item.Ignore
            if item == Item.Unknown:
               errorMessage("No help for " & $Yellow & secondWord & " " &
                     thirdWord & $Reset)
            elif item == Item.None:
               errorMessage("No help for " & $Yellow & secondWord & $Reset)
         # ====
         # EXIT
         # ====
         of Command.ExitSave:
            try:
               discard noise.historySave(historyFilename)
            except:
               errorMessage("Unable to save " & $Yellow & historyFilename & $Reset)
            try:
               lifePlan.save(lifePlanFilename)
            except:
               errorMessage("Unable to save " & $Yellow & lifePlanFilename & $Reset)
            return
         of Command.ExitNoSave:
            try:
               discard noise.historySave(historyFilename)
            except:
               errorMessage("Unable to save " & $Yellow & historyFilename & $Reset)
            return
         # =====
         # CLEAR
         # =====
         of Command.Clear:
            eraseScreen()
            stdout.setCursorPos(0, 0)
         # =====
         # ERASE
         # =====
         of Command.Erase:
            noise.historyClear()
         # ===
         # ADD
         # ===
         of Command.Add:
            case item
            of Item.Goal:
               lifePlan.addGoal(noise, remainder)
            of Item.Action:
               lifePlan.addAction(noise, remainder)
            of Item.Agreement:
               lifePlan.addAgreement(noise, remainder)
            of Item.Alert:
               lifePlan.addAlert(noise, remainder)
            of Item.Result:
               lifePlan.addResult(noise, remainder)
            else:
               errorMessage("Unknown command " & $Yellow & words[0] & " " &
                     words[1] & $Reset & ". Use " & $Yellow & "help" & $Reset & " for a list of commands")
         # ====
         # SHOW
         # ====
         of Command.Show:
            case item:
            of Item.Goal:
               lifePlan.showGoal()
            of Item.Action:
               lifePlan.showAction()
            of Item.Agreement:
               lifePlan.showAgreement()
            of Item.Alert:
               lifePlan.showAlert()
            of Item.Result:
               lifePlan.showResult()
            of Item.All:
               lifePlan.show(All)
            of Item.None:
               if lifePlan.goals == @[]:
                  errorMessage(ERROR_MESSAGES[10])
               else:
                  errorMessage("Unknown command " & $Yellow & words[0] & " " &
                        words[1] &
                     $Reset & ". Use " & $Yellow & "help" & $Reset & " for a list of commands")
            else:
               errorMessage("Unknown command " & $Yellow & words[0] & " " &
                     words[1] & $Reset & ". Use " & $Yellow & "help" & $Reset & " for a list of commands")
         # ======
         # UPDATE
         # ======
         of Command.Update:
            case item:
            of Item.Goal:
               lifePlan.updateGoal(noise, remainder)
            of Item.Action:
               lifePlan.updateAction(noise, remainder)
            of Item.Agreement:
               lifePlan.updateAgreement(noise, remainder)
            of Item.Alert:
               lifePlan.updateAlert(noise, remainder)
            of Item.Result:
               lifePlan.updateResult(noise, remainder)
            else:
               errorMessage("Unknown command " & $Yellow & words[0] & " " &
                     words[1] & $Reset & ". Use " & $Yellow & "help" & $Reset & " for a list of commands")
         # ======
         # REMOVE
         # ======
         of Command.Remove:
            case item:
            of Item.Goal:
               lifePlan.removeGoal(remainder)
            of Item.Action:
               lifePlan.removeAction(remainder)
            of Item.Agreement:
               lifePlan.removeAgreement(remainder)
            of Item.Alert:
               lifePlan.removeAlert(remainder)
            of Item.Result:
               lifePlan.removeResult(remainder)
            else:
               errorMessage("Unknown command " & $Yellow & words[0] & " " &
                     words[1] & $Reset & ". Use " & $Yellow & "help" & $Reset & " for a list of commands")
         # ====
         # ELSE
         # ====
         else:
            var message = words[0]
            if words.len >= 2 and firstCommand != Command.Unknown:
               case secondCommand
               of Command.None, Command.Unknown:
                  discard
               else:
                  message.add(" " & words[1])
            errorMessage("Unknown command " & $Yellow & message & $Reset &
                  ". Use " & $Yellow & "help" & $Reset & " for a list of commands")
         # ==============
         # ADD TO HISTORY
         # ==============
         # empty lines are skipped (at the start of the loop)
         if firstCommand != Command.Erase:
            noise.historyAdd(input)
 
