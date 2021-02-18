fun harpoon#nav(id) 
    call luaeval("require('harpoon.ui').nav(_A[1])", [a:id])
endfun

fun harpoon#cmd(cmd) 
    " TODO: I am sure I'll use this
endfun
