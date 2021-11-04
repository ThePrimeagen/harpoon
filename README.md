# WARNING
This is not fully baked, though used by several people.  If you experience any
issues, see some improvement you think would be amazing, or just have some
feedback for harpoon (or me), make a ticket!

![Harpoon](harpoon.png)
-- Image provided by Liberty_DevCap

# harpoon
The goal of Harpoon is to get you where you want with the fewest keystrokes.

## The Problem
You work on code.  The code base is medium, large, tiny, whatever.  You find
yourself frequenting a small set of files (maybe it depends on task) and you
are tired of using a fuzzy finder, :bnext/prev, alternate file doesn't quite
cut it, etc etc.

## The Other Problem
You want to execute some project specific commands or have any number of
persistent terminals that can be easily navigated to.

## The Solution
The ability to specify, or on the fly, mark and create persisting key strokes
to go to the files you want.

## The Other Solution
Unlimited terminals and navigation.

## Installation
### Requires Neovim version 0.5.0+
Simply install via your favorite plugin manager.

```vim
Plug 'nvim-lua/plenary.nvim' " don't forget to add this one if you don't have it yet!
Plug 'ThePrimeagen/harpoon'
```

## Harpooning
There are two modes of harpoon.  File navigation and terminal navigation.
Setup of harpoon configuration is at the bottom since its for more advanced use
cases.

### File Navigation
#### Mark a file
Marking a file is similar to vim global marks, but differ in a few key ways.

* They auto update their position
* They are unique _per project_.
* They can be hand edited vs replaced (swapping is easier)

To mark a file simply call the following lua function

```lua
:lua require("harpoon.mark").add_file()
```

This will mark the file and add it to the end of the mark list.

#### Navigate to file
To navigate to any of the marked files simply call the navigation function with
which index.

```lua
:lua require("harpoon.ui").nav_file(3) -- This will navigate to file 3
```

#### Manipulating current marks
There is a quick menu that will allow for you to edit your marks.  You can hand
edit the name, its position within the list, or remove it from the list.  To
bring up the quick list execute the following lua command.

```lua
:lua require("harpoon.ui").toggle_quick_menu()
```

You can simply edit this list as if it were a document in vim.  `:wq` to save
the new edits or `:q` to ignore the edits.  There is to save upon call to
toggle if you prefer that way.

You can also exit the list with `q` or `<ESC>`, which will call `toggle_quick_menu()` again.

### Terminal Navigation
#### Motivation for terminals in neovim
I want to use the terminal since I can gF and <c-w>gF to any errors arising
from execution that are within the terminal that are not appropriate for
something like dispatch. (not just running tests but perhaps a server that runs
for X amount of time before crashing).

I want the terminal to be persistent and I can return to one of many terminals
with some finger wizardry and reparse any of the execution information that was
not necessarily error related.

I would like to have commands that can be tied to terminals and sent them
without much thinking. Some sort of middle ground between vim-test and just
typing them into a terminal (configuring netflix's television project isn't
quite building and there are tons of ways to configure).

#### Navigating to a terminal
To navigate to a terminal simply provide an index and it will go.  If there is
no terminal in that index or the terminal has been closed by some means,
harpoon will create a new terminal at that location.

```lua
lua require("harpoon.term").gotoTerminal(1)
```

You can provide as high of a number as you would like.  There  is no terminal
count limitation though I personally find anything beyond two oft confusing.

#### Commands to terminal
Sometimes you wish to send commands to terminals that have been preconfigured
for a project.  To make this work properly you must predefine a command or hard
code it as part of the send process.

```lua
" This will send to terminal 1 either the predefined command 1 in the terminal
" config or "ls -la"
lua require("harpoon.term").sendCommand(1, 1)
lua require("harpoon.term").sendCommand(1, "ls -la")
```

#### Dynamic commands to terminal
This feature adds ability to change commands while working inside a project. 
Just call the following function to edit commands inside the list
```lua
lua require('harpoon.cmd-ui').toggle_quick_menu()
```

### Setup
Setup should be called once.

#### TODO: Make this callable more than once and just layer in the commands
Yes... A todo in a readme.  Deal with it.

#### The Configuration File
You can configure harpoon via lua in your rc.  Here is a simple example that
will add a specific command to a project.

##### Global Settings

```lua
Here is the set of global settings and their default values.

require("harpoon").setup({
    global_settings = {
        save_on_toggle = false,
        save_on_change = true,
        enter_on_sendcmd = false,
        excluded_filetypes = {"harpoon"}
    },
    ... your other configs ...
})
```

* `save_on_toggle` will set the marks upon calling `toggle` on the ui, instead
  of require `:w`.
* `save_on_change` will save the harpoon file upon every change.  If you don't
  enable this option (on by default) harpoon will not save any changes to your
  file.  It is very unreliable to save your harpoon on exit (at least that is
  what I have found).
* `enter_on_sendcmd` will set harpoon to run the command immediately as it's
    passed to the terminal when calling `sendCommand`.
* `excluded_filetypes` filetypes that you want to prevent from adding to the harpoon list menu.

#### Preconfigured Terminal Commands
These are project specific commands that you wish to execute on the regular.

```lua
require("harpoon").setup({
    projects = {
        -- Yes $HOME works
        ["$HOME/personal/vim-with-me/server"] = {
            term = {
                cmds = {
                    "./env && npx ts-node src/index.ts"
                }
            }
        },
```

## Debugging
Harpoon writes logs to a `harpoon.log` file that resides in Neovim's cache
path. (`:echo stdpath("cache")` to find where that is for you.)

By default, logging is enabled for warnings and above. This can be changed by
setting `vim.g.harpoon_log_level` variable to one of the following log levels:
`trace`, `debug`, `info`, `warn`, `error`, or `fatal`. Note that this would
have to be done **before** harpoon's `setup` call. Alternatively, it can be
more convenient to launch Neovim with an environment variable, e.g. `>
HARPOON_LOG=trace nvim`. In case both, `vim.g` and an environment variable are
used, the log level set by the environment variable overrules. Supplying an
invalid log level defaults back to warnings.
