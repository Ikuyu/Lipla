## :Author: Edwin (Ikuyu) Jonkvorst
## :Version: 0.1.0
##
## Api for building a life plan application
## ========================================
##
## A `LifePlan` consists of one or more of goals, actions, agreements and alerts.
## To achieve a goal one has to execute some actions.
## Every action is performed by fulfilling agreements.
## To keep the agreements, certain tempations need to be avoided.
## Alerts describe exactly how this is done.
##
## Goals are long-term accomplishments, actions are medium-term performances and agreements are short-term performances.
##
## .. code-block:: nim
##    import lifeplan
##
##    var myLifePlan = newLifePlan()
##
##    myLifePlan.add(newGoal("lose weight (target: 65 kg)"))
##    myLifePlan.goals[0].actions.add(newAction("follow Heigh Vegetable Diet"))
##    myLifePlan.goals[0].actions.add(newAction("hiking"))
##    myLifePlan.goals[0].actions[0].agreements.add(newAgreement("breakfast: soy yogurt with fruit (no bread/cereals); lunch: salad with light dressing (no bread); diner: replace pasta/rice/nudels with celeriac, cauliflower, broccoli, parsnip or zucchini"))
##    myLifePlan.goals[0].actions[1].agreements.add(newAgreement("take a 3-5 km hike on Monday, Wednesday and Saturday"))
##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("avoid the bread department in the supermarket"))
##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("prepare salad (cut/wash/chop the ingredients) for the next day in the evening"))
##    myLifePlan.goals[0].actions[1].agreements[0].alerts.add(newAlert("don't relax on the couch/turn on the television before doing the hike"))
#
# To convert a DateTime instance from/to a string, se the format/parse methods in the times module.
# A DateTime instance is store as 2012-04-23T18:25:43.511Z.

import json # json (de)serialization
import times # string
import xmltree # xml tree

type
   LifePlan* = ref object of RootObj
      ## Represents a life plan.
      ## A ``LifePlan`` consists of goals and some personal information.
      # avatar: image
      firstname*: string
      lastname*: string
      birthday*: string ## yyyy-MM-dd'T'HH:mm:sszzz. Example: "2000-01-01T12:00:00Z"
      address*: string
      zip*: string
      city*: string
      country*: string
      state*: string
      telephone*: string
      mobile*: string
      email*: string
      goals*: seq[Goal]
      date: string ## creation date: yyyy-MM-dd'T'HH:mm:sszzz. Example: "2000-01-01T12:00:00Z"
      about*: string ## desires/history/weaknesses/strengths/opportunities/threats
   Goal* = ref object of RootObj
      ## Represents a goal.
      ## Goals are evaluable.
      ## They are accomplished by executing some actions.
      ## Every goal is created at a certain date/time.
      date*: string ## creation date: yyyy-MM-dd'T'HH:mm:sszzz. Example: "2000-01-01T12:00:00Z"
      description*: string ## description
      actions*: seq[Action]
      results*: seq[Result] ## for process/product based evaluations
   Action* = ref object of RootObj
      ## Represents an action.
      ## Actions are performed by fulfilling agreements.
      ## They are created at a certain date/time.
      date*: string ## creation date: yyyy-MM-dd'T'HH:mm:sszzz. Example: "2000-01-01T12:00:00Z"
      description*: string ## description
      agreements*: seq[Agreement]
   Agreement* = ref object of RootObj
      ## Represents an agreement.
      ## Agreements are violated by temptations.
      ## They are created at a certain date/time.
      date*: string ## creation date: yyyy-MM-dd'T'HH:mm:sszzz. Example: "2000-01-01T12:00:00Z"
      description*: string ## description
      alerts*: seq[Alert]
   Alert* = ref object of RootObj
      ## Represents an alert.
      ## Alerts describe how to avoid temptations.
      ## They are created at a certain date/time.
      date*: string ## creation date: yyyy-MM-dd'T'HH:mm:sszzz. Example: "2000-01-01T12:00:00Z"
      description*: string ## description
   Result* = ref object of RootObj
      ## Represents a result.
      ## Results are reported based on a process/product evaluation.
      ## They are created at a certain date/time.
      date*: string ## creation date: yyyy-MM-dd'T'HH:mm:sszzz. Example: "2000-01-01T12:00:00Z"
      description*: string ## description

# no need for getters/setters since there are no private fields

proc newLifePlan*(firstname = "", lastname = "", birthday = $now(),
      address = "", zip = "", city = "", country = "", state = "",
      telephone = "", mobile = "", email = "", date = $now(),
      about = ""): LifePlan =
   ## Creates a new ``LifePlan``.
   ##
   ## The fields ``birthday`` and ``date`` are of the type 'string' due to json (de)serialisation restrictions.
   ## They can be given a custom (date/time) value with the ``initDateTime`` procedure from the ``times`` module.
   ## The ``times`` module is part of Nim's standard library and returns a string using this format: yyyy-MM-dd'T'HH:mm:sszzz.
   ## Example: "2000-01-01T12:00:00Z".
   ## The string can be parsed back again using the ``parse`` procedure from the same ``times`` module.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var myLifePlan = newLifePlan("Ikuyu")
   ##    myLifePlan.goals.add(newGoal("To lose weight (target: 65 kg)"))
   ##
   ## You can add results, actions, agreements and/or alerts with the build in generic ``add`` method.
   ##
   ## .. code-block:: nim
   ##    myLifePlan.goals[0].actions.add(newAction(("follow Heigh Vegetable Diet"))
   ##    myLifePlan.goals[0].actions[0].agreements.add(newAgreement("breakfast: soy yogurt with fruit (no bread/cereals); lunch: salad with light dressing (no bread); diner: replace pasta/rice/nudels with celeriac, cauliflower, broccoli, parsnip or zucchini"))
   ##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("avoid the bread department in the supermarket"))
   ##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("prepare salad (cut/wash/chop the ingredients) for the next day in the evening"))
   ##    myLifePlan.goals[0].results.add(newResult("in the first week I desired for other foods, after that it got easier; lost 2 kg in the first month"))
   ##
   ## Removing goals, results, actions etc. is just as easy. Just use the built in generic ``delete`` method.
   ##
   ## .. code-block:: nim
   ##    myLifePlan.goals[0].actions.delete(0)

   result = new LifePlan
   result.firstname = firstname
   result.lastname = lastname
   result.birthday = birthday
   result.address = address
   result.zip = zip
   result.city = city
   result.country = country
   result.state = state
   result.telephone = telephone
   result.mobile = mobile
   result.email = email
   result.goals = @[]
   result.date = date
   result.about = about

proc newGoal*(description = "", date = $now()): Goal =
   ## Creates a new ``Goal``.
   ##
   ## The field ``date`` is of the type 'string' due to json (de)serialisation restrictions.
   ## It can be given a custom (date/time) value with the ``initDateTime`` procedure from the ``times`` module.
   ## The ``times`` module is part of Nim's standard library and returns a string using this format: yyyy-MM-dd'T'HH:mm:sszzz.
   ## Example: "2000-01-01T12:00:00Z".
   ## The string can be parsed back again using the ``parse`` procedure from the same ``times`` module.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var
   ##       firstGoal: Goal
   ##       seondGoal = newGoal("lose weight (target: 65 kg)")
   ##
   ##    firstGoal = newGoal()
   ##    firstGoal.description = "start my own company"
   result = new Goal
   result.date = date
   result.description = description
   result.actions = @[]
   result.results = @[]

proc newResult*(description = "", date = $now()): Result =
   ## Creates a new ``Result``.
   ##
   ## The field ``date`` is of the type 'string' due to json (de)serialisation restrictions.
   ## It can be given a custom (date/time) value with the ``initDateTime`` procedure from the ``times`` module.
   ## The ``times`` module is part of Nim's standard library and returns a string using this format: yyyy-MM-dd'T'HH:mm:sszzz.
   ## Example: "2000-01-01T12:00:00Z".
   ## The string can be parsed back again using the ``parse`` procedure from the same ``times`` module.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var
   ##       result = newResult("in the first week I desired for other foods, after that it got easier; lost 2 kg in the first month")
   result = new Result
   result.date = date
   result.description = description

proc newAction*(description = "", date = $now()): Action =
   ## Creates a new ``Action``.
   ##
   ## The field ``date`` is of the type 'string' due to json (de)serialisation restrictions.
   ## It can be given a custom (date/time) value with the ``initDateTime`` procedure from the ``times`` module.
   ## The ``times`` module is part of Nim's standard library and returns a string using this format: yyyy-MM-dd'T'HH:mm:sszzz.
   ## Example: "2000-01-01T12:00:00Z".
   ## The string can be parsed back again using the ``parse`` procedure from the same ``times`` module.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var
   ##       action = newAction("follow Heigh Vegetable Diet")
   result = new Action
   result.date = date
   result.description = description
   result.agreements = @[]

proc newAgreement*(description = "", date = $now()): Agreement =
   ## Creates a new ``Agreement``.
   ##
   ## The field ``date`` is of the type 'string' due to json (de)serialisation restrictions.
   ## It can be given a custom (date/time) value with the ``initDateTime`` procedure from the ``times`` module.
   ## The ``times`` module is part of Nim's standard library and returns a string using this format: yyyy-MM-dd'T'HH:mm:sszzz.
   ## Example: "2000-01-01T12:00:00Z".
   ## The string can be parsed back again using the ``parse`` procedure from the same ``times`` module.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var
   ##       agreement = newAgreement("breakfast: soy yogurt with fruit (no bread/cereals); lunch: salad with light dressing (no bread); diner: replace pasta/rice/nudels with celeriac, cauliflower, broccoli, parsnip or zucchini")
   result = new Agreement
   result.date = date
   result.description = description
   result.alerts = @[]

proc newAlert*(description = "", date = $now()): Alert =
   ## Creates a new ``Alert``.
   ##
   ## The field ``date`` is of the type 'string' due to json (de)serialisation restrictions.
   ## It can be given a custom (date/time) value with the ``initDateTime`` procedure from the ``times`` module.
   ## The ``times`` module is part of Nim's standard library and returns a string using this format: yyyy-MM-dd'T'HH:mm:sszzz.
   ## Example: "2000-01-01T12:00:00Z".
   ## The string can be parsed back again using the ``parse`` procedure from the same ``times`` module.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var
   ##       alert = newAlert("avoid the bread department in the supermarket")
   result = new Alert
   result.date = date
   result.description = description

method isEmpty*(lifePlan: LifePlan): bool {.base.} =
   ## Checks whether a ``LifePlan`` is empty or not.
   ## The fields ``birthday`` and ``date`` are ignored.
   if lifePlan.firstname == "" and
      lifePlan.lastname == "" and
      #lifePlan.birthday == "" and
      lifePlan.address == "" and
      lifePlan.zip == "" and
      lifePlan.city == "" and
      lifePlan.country == "" and
      lifePlan.state == "" and
      lifePlan.telephone == "" and
      lifePlan.mobile == "" and
      lifePlan.email == "" and
      lifePlan.goals == @[] and
      #lifePlan.date == "" and
      lifePlan.about == "":
      result = true
   else:
      result = false

method clear*(lifePlan: LifePlan) {.base.} =
   ## Clears a ``LifePlan``.
   ##
   ## The field ``birthday`` and ``date`` are reset with the 'now' procedure from the ``times`` module.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var myLifePlan = newLifePlan()
   ##
   ##    myLifePlan.add(newGoal("To lose weight (target: 65 kg)"))
   ##    myLifePlan.goals[0].actions.add(newAction(("follow Heigh Vegetable Diet"))
   ##    myLifePlan.goals[0].actions[0].agreements.add(newAgreement("breakfast: soy yogurt with fruit (no bread/cereals); lunch: salad with light dressing (no bread); diner: replace pasta/rice/nudels with celeriac, cauliflower, broccoli, parsnip or zucchini"))
   ##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("avoid the bread department in the supermarket"))
   ##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("prepare salad (cut/wash/chop the ingredients) for the next day in the evening"))
   ##    myLifePlan.goals[0].results.add(newResult("in the first week I desired for other foods, after that it got easier; lost 2 kg in the first month"))
   ##    myLifePlan.clear()
   lifePlan.firstname = ""
   lifePlan.lastname = ""
   lifePlan.birthday = $now()
   lifePlan.address = ""
   lifePlan.zip = ""
   lifePlan.city = ""
   lifePlan.country = ""
   lifePlan.state = ""
   lifePlan.telephone = ""
   lifePlan.mobile = ""
   lifePlan.email = ""
   lifePlan.goals = @[]
   lifePlan.date = $now()
   lifePlan.about = ""

proc load*(filename: string): LifePlan =
   ## Reads a lifePlan stored in json format. Returns a ``LifePlan``.
   ## May throw an IO exception.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var myLifePlan = newLifePlan()
   ##
   ##    myLifePlan.load()
   result = new LifePlan
   result = readFile(filename).parseJson().to(
         LifePlan) # deserialisation from a json formatted string

method save*(lifePlan: LifePlan, filename: string) {.base.} = # default save format is json
   ## Stores a ``LifePlan`` in json format.
   ## May throw an IO exception.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var myLifePlan = newLifePlan()
   ##
   ##    myLifePlan.add(newGoal("To lose weight (target: 65 kg)"))
   ##    myLifePlan.goals[0].actions.add(newAction(("follow Heigh Vegetable Diet"))
   ##    myLifePlan.goals[0].actions[0].agreements.add(newAgreement("breakfast: soy yogurt with fruit (no bread/cereals); lunch: salad with light dressing (no bread); diner: replace pasta/rice/nudels with celeriac, cauliflower, broccoli, parsnip or zucchini"))
   ##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("avoid the bread department in the supermarket"))
   ##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("prepare salad (cut/wash/chop the ingredients) for the next day in the evening"))
   ##    myLifePlan.goals[0].results.add(newResult("in the first week I desired for other foods, after that it got easier; lost 2 kg in the first month"))
   ##    myLifePlan.save()
   writeFile(filename, $(%*lifePlan)) # serialization to a json formatted string

method exportXml*(lifePlan: LifePlan, filename: string) {.base.} =
   ## Stores a ``LifePlan`` in xml format.
   ## May throw an IO exception.
   ##
   ## **Examples**
   ##
   ## .. code-block:: nim
   ##    var myLifePlan = newLifePlan()
   ##
   ##    myLifePlan.add(newGoal("To lose weight (target: 65 kg)"))
   ##    myLifePlan.goals[0].actions.add(newAction(("follow Heigh Vegetable Diet"))
   ##    myLifePlan.goals[0].actions[0].agreements.add(newAgreement("breakfast: soy yogurt with fruit (no bread/cereals); lunch: salad with light dressing (no bread); diner: replace pasta/rice/nudels with celeriac, cauliflower, broccoli, parsnip or zucchini"))
   ##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("avoid the bread department in the supermarket"))
   ##    myLifePlan.goals[0].actions[0].agreements[0].alerts.add(newAlert("prepare salad (cut/wash/chop the ingredients) for the next day in the evening"))
   ##    myLifePlan.goals[0].results.add(newResult("in the first week I desired for other foods, after that it got easier; lost 2 kg in the first month"))
   ##    myLifePlan.exportXml()
   var nodes: seq[XmlNode] = @[]
   var firstname = newElement("firstname")
   firstname.add(newText(lifePlan.firstname))
   nodes.add(firstname)
   var lastname = newElement("lastname")
   lastname.add(newText(lifePlan.lastname))
   nodes.add(lastname)
   var birthday = newElement("birthday")
   birthday.add(newText($lifePlan.birthday))
   nodes.add(birthday)
   var address = newElement("address")
   address.add(newText(lifePlan.address))
   nodes.add(address)
   var zip = newElement("zip")
   zip.add(newText(lifePlan.zip))
   nodes.add(zip)
   var city = newElement("city")
   city.add(newText(lifePlan.city))
   nodes.add(city)
   var country = newElement("country")
   country.add(newText(lifePlan.country))
   nodes.add(country)
   var state = newElement("state")
   state.add(newText(lifePlan.state))
   nodes.add(state)
   var telephone = newElement("telephone")
   telephone.add(newText(lifePlan.telephone))
   nodes.add(telephone)
   var mobile = newElement("mobile")
   mobile.add(newText(lifePlan.mobile))
   nodes.add(mobile)
   var email = newElement("email")
   email.add(newText(lifePlan.email))
   nodes.add(email)
   var date = newElement("date")
   date.add(newText($lifePlan.date))
   nodes.add(date)
   var about = newElement("about")
   about.add(newText(lifePlan.about))
   nodes.add(about)
   for goal in lifePlan.goals:
      var nGoal = newElement("goal")
      nGoal.add(newComment($goal.date))
      nGoal.add(newText(goal.description))
      for result in goal.results:
         var nResult = newElement("result")
         nResult.add(newComment($result.date))
         nResult.add(newText(result.description))
         nGoal.add(nResult)
      for action in goal.actions:
         var nAction = newElement("action")
         nAction.add(newComment($action.date))
         nAction.add(newText(action.description))
         nGoal.add(nAction)
         for agreement in action.agreements:
            var nAgreement = newElement("agreement")
            nAgreement.add(newComment($agreement.date))
            nAgreement.add(newText(agreement.description))
            #nAction.add(nAgreement)
            nGoal.add(nAction)
            for alert in agreement.alerts:
               var nAlert = newElement("alert")
               nAlert.add(newComment($alert.date))
               nAlert.add(newText(alert.description))
               #nAgreement.add(nAlert)
               #nAction.add(nAgreement)
               #nGoal.add(nAction)
               nGoal.add(nAlert)
      nodes.add(nGoal)
   writeFile(filename, $newXmlTree("lifePlan", nodes))
