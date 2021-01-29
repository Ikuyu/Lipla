**Lipla**

**A command line oriented lifeplan assistent**

Lipla can help you accomplish your goals; the goals you want to achieve before you die and leave this so called planet earth.

To accomplish a goal you'll have to translate it into one or more actions. Every action is accomplished through a series of agreements. Agreements come with alerts. Alerts are the things you should avoid doing in order to reach your goals.

Command line options:

<pre>Usage:
   lipla [options] [&lt;file&gt;[&lt;file&gt;]]

Options:
   -x, --export    Exports a life plan to xml
   -h, --help      Prints help information
   -v, --version   Prints version information
</pre>

By default your life plan will be saved in your user directory. Filename: 'lipla.dat'.

The maximum number of allowed items is 7. However, you're not advised to work with more than 3 goals at once.

**Commands**

Within the application, type 'h' or 'help' for a list of commands.

Use 's' or 'show' to print a list of all goals, actions, agreements, alerts and/or results. To exit Lipla without saving type 'x!' or 'exit!'. Otherwise use 'x' or exit'.

*Commands used for adding items*

- ```add goal [description]```<br/>
- ```add action <goal number> [description]```<br/>
- ```add agreement <goal number> <action number> [description]```<br/>
- ```add alert <goal number> <action number> <agreement number> [description]```<br/>
- ```add result <goal number> [description]```

This command will ask for a description if it is not already given.

*Commands used for showing items*

- ```show goals```<br/>
- ```show actions```<br/>
- ```show agreements```<br/>
- ```show alerts```<br/>
- ```show results```

*Commands used for updating items*

- ```update goal <goal number> [description]```<br/>
- ```update action <goal number> <action number> [description]```<br/>
- ```update agreement <goal number> <action number> <agreement number> [description]```<br/>
- ```update alert <goal number> <action number> <agreement number> <alert number> [description]```<br/>
- ```update result <goal number> <result number> [description]```

This command will ask for a description if it is not already given.

*Commands used for removing items*

- ```remove goal <goal number>```<br/>
- ```remove action <goal number> <action number>```<br/>
- ```remove agreement <goal number> <action number> <agreement number>```<br/>
- ```remove alert <goal number> <action number> <agreement number> <alert number>```<br/>
- ```remove result <goal number> <result number>```

The commands follow the usual *action verb* pattern (show goals), but the reverse is also possible (goals show).

**Compiling from source**

1. Navigate to the folder where you want to compile this project.<br>
2. Execute the following commands (if you are on macOS):

```
git clone https://github.com/Ikuyu/Lipla
nimble install noise@#head
nimble install docopt
nimble macesc
```

There's a nimble task to cross compile Lipla for Windows as well (winesc).

**Windows 10**

To use Lipla on Windows, the ANSI escape code registry key must be enabled. This can be done, by running the following instruction in the Command Prompt:

<pre>reg add HKEY_CURRENT_USER\Console /v VirtualTerminalLevel /t REG_DWORD /d 0x00000001 /f
</pre>

**Contact**

This project is hosted on http://lipla.github.io.

**Author**

Lipla is the work of Edwin (Ikuyu) Jonkvorst hetlevenkronen@gmail.com: Developer, founder.
