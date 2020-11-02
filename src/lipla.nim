# :Author: Edwin (Ikuyu) Jonkvorst
# :Version: 0.1.0
#
# lipla (a command line oriented life plan assistent)
# ===================================================
#
# Lipla supports unicode characters, if the terminal supports it.
# Name of the webapp: iCoach.
# Compile with -d:esc_exit_editing, or: --define:esc_exit_editing.

import lifeplan # api for building a life plan application
import repl # lipla interpreter
import docopt # command line parser
from os import fileExists, getHomeDir, joinPath

const
   VERSION_NR = "0.1.0"
   DEFAULT_XML_FILENAME = "lipla.xml"
   YELLOW = "\e[33m" # 33 = normal, 93 = bright
   RESET = "\e[0m"
   HELP = """
Edwin (Ikuyu) Jonkvorst <hetlevenkronen@gmail.com>
A command line oriented life plan assistent

Usage:
   lipla [options] [<file>[<file>]]

Options:
   -x, --export    Exports a life plan to xml
   -h, --help      Prints help information
   -v, --version   Prins version information
"""

proc main() =
   let args = docopt(HELP, version = "Lipla: " & VERSION_NR)
   var liplaFilename = joinPath(getHomeDir(),
         DEFAULT_LIFEPLAN_FILENAME) # default lipla data filename (stored in the users home directory)
   let historyFilename = joinPath(getHomeDir(),
         DEFAULT_HISTORY_FILENAME) # default lipla history filename (will be stored in the users home directory)
 #
 # =======================
 # COMMAND LINE PARAMETERS
 # =======================
 #
 # =========================
 # OPTION: --EXPORT (TO XML)
 # =========================
   if args["--export"]:
      var lifePlan = newLifePlan()
      # if at least one argument (filename)is given
      if @(args["<file>"]).len > 0:
         liplaFilename = @(args["<file>"])[0] # use that filename to load (json) data from it
      # otherwise, use the default filename
      try:
         # try to load the (json) data
         lifePlan = load(liplaFilename)
      # whatever the exception might be...
      except:
         # print this error message
         errorMessage("Unable to load data from " & YELLOW & liplaFilename &
               RESET) # prints the filename in yellow
         quit()
      var xmlFile = DEFAULT_XML_FILENAME
      # if there is a second argument (filename) given
      if @(args["<file>"]).len == 1:
         # use that filename to save the (xml) data to
         xmlFile = @(args["<file>"])[1]
      try:
         # try to save the (xml) data
         lifePlan.exportXml(xmlFile)
      # whatever the error...
      except:
         # print this error message
         errorMessage("Unable to export data to " & YELLOW & xmlFile &
               RESET) # prints the filename in yellow
      quit() # wheter the export was succesful or not, the (export) job is done
   # =====================================================
   # OPTIONS: NONE (BUT THERE IS/ARE ONE OR MORE ARGUMENTS
   # =====================================================
   if @(args["<file>"]).len > 0:
      # only the first argument is used to refer to a file that contains lipla (json) data
      liplaFilename = @(args["<file>"])[0]
   # ==============
   # START THE REPL
   # ==============
   repl(historyFilename, liplaFilename)

when isMainModule:
   main()
