" TODO: Make this vim compatible.

" How to do this but much better?
let g:win_ctrl_buf_list = [0, 0, 0, 0]

fun! Harpoon_GotoTerminal(ctrlId)
    if (a:ctrlId > 9) || (a:ctrlId < 0)
        echo "CtrlID must be between 0 - 9"
        return
    end

    let contents = g:win_ctrl_buf_list[a:ctrlId]
    if type(l:contents) != v:t_list
        " Create the terminal
        exe has("nvim") ? "terminal" : "terminal ++curwin"
        call Harpoon_SetTerminal(a:ctrlId)
    end
    let contents = g:win_ctrl_buf_list[a:ctrlId]
    if type(l:contents) != v:t_list
        echo "Unable to create a terminal or find the terminal's information."
    end

    let bufh = l:contents[1]
    if !bufexists(bufh)
        " Create the terminal
        exe has("nvim") ? "terminal" : "terminal ++curwin"
        call Harpoon_SetTerminal(a:ctrlId)
    endif

    let contents = g:win_ctrl_buf_list[a:ctrlId]
    let bufh = l:contents[1]
    exe "b" . l:bufh
endfun

fun! Harpoon_SetTerminal(ctrlId)
    if &buftype != "terminal"
        echo "You must be in a terminal to execute this command"
        return
    end
    if (a:ctrlId > 9) || (a:ctrlId < 0)
        echo "CtrlID must be between 0 - 3"
        return
    end

    let g:win_ctrl_buf_list[a:ctrlId] = [has_key(b:, "terminal_job_id") ? b:terminal_job_id : 0, bufnr()]
endfun

fun! Harpoon_SendTerminalCommand(ctrlId, command)
    if (a:ctrlId > 9) || (a:ctrlId < 0)
        echo "CtrlID must be between 0 - 9"
        return
    end
    let contents = g:win_ctrl_buf_list[a:ctrlId]
    if type(l:contents) != v:t_list
        echo "No terminal created, sorry for not creating this in the background..."
        call GotoBuffer(a:ctrlId)
    end
    let contents = g:win_ctrl_buf_list[a:ctrlId]
    if type(l:contents) != v:t_list
        echo "Unable to send command to terminal"
    end

    if has("nvim")
        let job_id = l:contents[0]
        call chansend(l:job_id, a:command)
    else
        let bufh = l:contents[1]
        call term_sendkeys(l:bufh, a:command)
    endif
endfun
