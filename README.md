# harpoon
The goal of Harpoon is to get you where you want with the fewest keystrokes.

## The Problem
You work on code.  The code base is medium, large, tiny, whatever.  You find
yourself frequenting a small set of files (maybe it depends on task) and you
are tired of using a fuzzy finder, :bnext/prev, alternate file doesn't quite
cut it, etc etc.

## The Solution
The ability to specify, or on the fly, mark and create persisting key strokes
to go to the files you want.  This includes terminal navigation.

## Installation
Simply install via your favorite plugin manager.

```
Plug 'ThePrimeagen/harpoon'
```

## Harpooning

### The Basics
Harpoon provides up to 4 slots for terminals.  Now you don't want to overload
terminals with everything.  I just tend to think about this as project specific
tasks.  Such as, `yarn lint`, `yarn test`, or some command based off of current
file.

Personally I only use 1 terminal.  I have no use for multiple terminals, but it
does provide the hooks for that.

### Navigation
To start navigating with Harpoon you simply `:call GotoBuffer(<bufnu>)`.  This
will create / navigate to the terminal in current buffer.

`bufnu`: can be a number from 0 - 3.  As stated above, there are up to 4 slots.


### Sending Commands
Where Harpoon shines is in local configs.

To setup a local config (per project) you must have a `.nvimrc` in the root of
your project (where you open up vim) and you must have the following sets in your root vimrc.


```
set exrc
set secure "optional, but it prevents harmful scripts from editing
           "I don't have this option on
```

#### Local Configuration example
For [VimDeathmatch](https://github.com/VimDeathmatch/server) we have a local
config for running commands.  Here is an example.

```
nnoremap <leader>ce :call SendTerminalCommand(0, "cd ~/personal/VimDeathmatch/server/server && npm run test" . expand("%") . "\n")<CR>
```

1.  I have `c` as the start into my local commands.
2.  e = middle finger, home row on Dvorak.  Power finger.
3.  Setup your own commands


That means when I am in Deathmatch and I want to test my current file I press
`<leader>ce` and it will open a terminal if there isn't one opened and execute
the commands.  I could of made that command a lot better, I was just in a hurry
:)  Forgive me.

#### General Navigation examples
Personally I have the following remaps in my root rc.

```
nmap <leader>tu :call GotoBuffer(0)<CR>
nmap <leader>te :call GotoBuffer(1)<CR>
nmap <leader>to :call GotoBuffer(2)<CR>
nmap <leader>ta :call GotoBuffer(3)<CR>
```

Same concept as before.  `t` is my entrence into the terminal world and aoeu is
my homerow.  All power positions.

