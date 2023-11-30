<div align="center">

# Harpoon
##### Getting you where you want with the fewest keystrokes.

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.5+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
</div>

![Harpoon](harpoon.png)
-- image provided by **Bob Rust**

## ⇁ TOC
* [The Problems](#-The-Problems)
* [The Solutions](#-The-Solutions)
* [Installation](#-Installation)
* [Getting Started](#-Getting-Started)
* [Social](#-Social)
* [Note to legacy Harpoon 1 users](#-Note-to-legacy-Harpoon-1-users)

## ⇁ The Problems
1. You're working on a codebase. medium, large, tiny, whatever. You find
yourself frequenting a small set of files and you are tired of using a fuzzy finder,
`:bnext` & `:bprev` are getting too repetitive, alternate file doesn't quite cut it, etc etc.
1. You want to execute some project specific commands or have any number of
persistent terminals that can be easily navigated to.

## ⇁ The Solutions
1. The ability to specify, or on the fly, mark and create persisting key strokes
to go to the files you want.
1. Unlimited terminals and navigation.

## ⇁ Installation
* neovim 0.8.0+ required
* install using your favorite plugin manager (i am using `packer` in this case)
```lua
use "nvim-lua/plenary.nvim" -- don't forget to add this one if you don't have it yet!
use {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    requires = { {"nvim-lua/plenary.nvim"} }
}
```

## ⇁ Getting Started

### Quick Note
You will want to add your style of remaps and such to your neovim dotfiles with
the shortcuts you like.  My shortcuts are for me.  Me alone.  Which also means
they are designed with dvorak in mind (My layout btw, I use dvorak btw).

### harpoon:setup
it is a requirement to call `harpoon:setup()`.  This is required due to
autocmds setup.

### Basic Setup
Here is my basic setup

```lua
local harpoon = require("harpoon")

harpoon:setup()

vim.keymap.set("n", "<leader>a", function() harpoon:list():append() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-t>", function() harpoon.ui:select(2) end)
vim.keymap.set("n", "<C-n>", function() harpoon.ui:select(3) end)
vim.keymap.set("n", "<C-s>", function() harpoon.ui:select(4) end)
```

## ⇁ Social
For questions about Harpoon, there's a #harpoon channel on [the Primeagen's Discord](https://discord.gg/theprimeagen) server.
* [Discord](https://discord.gg/theprimeagen)
* [Twitch](https://www.twitch.tv/theprimeagen)
* [Twitter](https://twitter.com/ThePrimeagen)

## ⇁ Note to legacy Harpoon 1 users
Original Harpoon will remain in a frozen state and i will merge PRs in with _no
code review_ for those that wish to remain on that.  Harpoon 2 is significantly
better and allows for MUCH greater control.  Please migrate to that (will
become `master` within the next few months).

