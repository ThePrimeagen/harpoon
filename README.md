<div align="center">

# Harpoon
##### Getting you where you want with the fewest keystrokes.

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
</div>

![Harpoon](harpoon.png)
-- image provided by **Bob Rust**


## ⇁  WIP
This is not fully baked, though used by several people. If you experience any
issues, see some improvement you think would be amazing, or just have some
feedback for harpoon (or me), make an issue!


## ⇁ The Problems:
1. You're working on a codebase. medium, large, tiny, whatever. You find
yourself frequenting a small set of files and you are tired of using a fuzzy finder,
`:bnext` & `:bprev` are getting too repetitive, alternate file doesn't quite cut it, etc etc.
1. You want to execute some project specific commands or have any number of
persistent terminals that can be easily navigated to.


## ⇁  The Solutions:
1. The ability to specify, or on the fly, mark and create persisting key strokes
to go to the files you want.
1. Unlimited terminals and navigation.


## ⇁ Installation
* neovim 0.5.0+ required
* install using your favorite plugin manager (`vim-plug` in this example)
```vim
Plug 'nvim-lua/plenary.nvim' " don't forget to add this one if you don't have it yet!
Plug 'ThePrimeagen/harpoon'
```

## ⇁ Harpooning
here we'll explain how to wield the power of the harpoon:


### Marks
you mark files you want to revisit later on
```lua
:lua require("harpoon.mark").add_file()
```

### File Navigation
view all project marks with:
```lua
:lua require("harpoon.ui").toggle_quick_menu()
```
you can go up and down the list, enter, delete or reorder. `q` and `<ESC>` exit and save the menu

you also can switch to any mark without bringing up the menu, use the below with the desired mark index
```lua
:lua require("harpoon.ui").nav_file(3)                  -- navigates to file 3
```
you can also cycle the list in both directions
```lua
:lua require("harpoon.ui").nav_next()                   -- navigates to next mark
:lua require("harpoon.ui").nav_prev()                   -- navigates to previous mark
```
from the quickmenu, open a file in: 
a vertical split with control+v,
a horizontal split with control+x, 
a new tab with control+t

### Terminal Navigation
this works like file navigation except that if there is no terminal at the specified index
a new terminal is created.
```lua
lua require("harpoon.term").gotoTerminal(1)             -- navigates to term 1
```

### Commands to Terminals
commands can be sent to any terminal
```lua
lua require("harpoon.term").sendCommand(1, "ls -La")    -- sends ls -La to tmux window 1
```
further more commands can be stored for later quick
```lua
lua require('harpoon.cmd-ui').toggle_quick_menu()       -- shows the commands menu
lua require("harpoon.term").sendCommand(1, 1)           -- sends command 1 to term 1
```

### Tmux Support
tmux is supported out of the box and can be used as a drop-in replacement to normal terminals
by simply switching `'term' with 'tmux'` like so

```lua
lua require("harpoon.tmux").gotoTerminal(1)             -- goes to the first tmux window
lua require("harpoon.tmux").sendCommand(1, "ls -La")    -- sends ls -La to tmux window 1
lua require("harpoon.tmux").sendCommand(1, 1)           -- sends command 1 to tmux window 1
```

`sendCommand` and `goToTerminal` also accept any valid [tmux pane identifier](https://man7.org/linux/man-pages/man1/tmux.1.html#COMMANDS).
```lua
lua require("harpoon.tmux").gotoTerminal("{down-of}")   -- focus the pane directly below
lua require("harpoon.tmux").sendCommand("%3", "ls")     -- send a command to the pane with id '%3'
```

Once you switch to a tmux window you can always switch back to neovim, this is a
little bash script that will switch to the window which is running neovim.

In your `tmux.conf` (or anywhere you have keybinds), add this
```bash
bind-key -r G run-shell "path-to-harpoon/harpoon/scripts/tmux/switch-back-to-nvim"
```

### Telescope Support
1st register harpoon as a telescope extension
```lua
require("telescope").load_extension('harpoon')
```
currently only marks are supported in telescope
```
:Telescope harpoon marks
```

## ⇁ Configuration
if configuring harpoon is desired it must be done through harpoons setup function
```lua
require("harpoon").setup({ ... })
```

### Global Settings
here are all the available global settings with their default values
```lua
global_settings = {
    -- sets the marks upon calling `toggle` on the ui, instead of require `:w`.
    save_on_toggle = false,

    -- saves the harpoon file upon every change. disabling is unrecommended.
    save_on_change = true,

    -- sets harpoon to run the command immediately as it's passed to the terminal when calling `sendCommand`.
    enter_on_sendcmd = false,

    -- closes any tmux windows harpoon that harpoon creates when you close Neovim.
    tmux_autoclose_windows = false,

    -- filetypes that you want to prevent from adding to the harpoon list menu.
    excluded_filetypes = { "harpoon" },

    -- set marks specific to each git branch inside git repository
    mark_branch = false,

    -- enable tabline with harpoon marks
    tabline = false,
    tabline_prefix = "   ",
    tabline_suffix = "   ",

    -- enable vim notifications when marking files 
    enable_notifications = true,
}
```


### Preconfigured Terminal Commands
to preconfigure terminal commands for later use
```lua
projects = {
    -- Yes $HOME works
    ["$HOME/personal/vim-with-me/server"] = {
        term = {
            cmds = {
                "./env && npx ts-node src/index.ts"
            }
        }
    }
}
```

## ⇁ Logging
- logs are written to `harpoon.log` within the nvim cache path (`:echo stdpath("cache")`)
- available log levels are `trace`, `debug`, `info`, `warn`, `error`, or `fatal`. `warn` is default
- log level can be set with `vim.g.harpoon_log_level` (must be **before** `setup()`)
- launching nvim with `HARPOON_LOG=debug nvim` takes precedence over `vim.g.harpoon_log_level`.
- invalid values default back to `warn`.

## ⇁ Others
#### How do Harpoon marks differ from vim global marks
they serve a similar purpose however harpoon marks differ in a few key ways:
1. They auto update their position within the file
1. They are saved _per project_.
1. They can be hand edited vs replaced (swapping is easier)

#### The Motivation behind Harpoon terminals
1. I want to use the terminal since I can gF and <c-w>gF to any errors arising
from execution that are within the terminal that are not appropriate for
something like dispatch. (not just running tests but perhaps a server that runs
for X amount of time before crashing).
1. I want the terminal to be persistent and I can return to one of many terminals
with some finger wizardry and reparse any of the execution information that was
not necessarily error related.
1. I would like to have commands that can be tied to terminals and sent them
without much thinking. Some sort of middle ground between vim-test and just
typing them into a terminal (configuring netflix's television project isn't
quite building and there are tons of ways to configure).

#### Use a dynamic width for the Harpoon popup menu
Sometimes the default width of `60` is not wide enough.
The following example demonstrates how to configure a custom width by setting
the menu's width relative to the current window's width.

```lua
require("harpoon").setup({
    menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
    }
})
```


#### Tabline

By default, the tabline will use the default theme of your theme.  You can customize by editing the following highlights:

* HarpoonInactive
* HarpoonActive
* HarpoonNumberActive
* HarpoonNumberInactive

Example to make it cleaner:

```lua
vim.cmd('highlight! HarpoonInactive guibg=NONE guifg=#63698c')
vim.cmd('highlight! HarpoonActive guibg=NONE guifg=white')
vim.cmd('highlight! HarpoonNumberActive guibg=NONE guifg=#7aa2f7')
vim.cmd('highlight! HarpoonNumberInactive guibg=NONE guifg=#7aa2f7')
vim.cmd('highlight! TabLineFill guibg=NONE guifg=white')
```

Result: 
![tabline](https://i.imgur.com/8i8mKJD.png) 

## ⇁ Social
For questions about Harpoon, there's a #harpoon channel on [the Primagen's Discord](https://discord.gg/theprimeagen) server.  
* [Discord](https://discord.gg/theprimeagen)
* [Twitch](https://www.twitch.tv/theprimeagen)
* [Twitter](https://twitter.com/ThePrimeagen)
