" TODO: Make this vim compatible.

" How to do this but much better?
let g:win_ctrl_buf_list = [0, 0, 0, 0]

fun! GotoBuffer(ctrlId)
    if (a:ctrlId > 9) || (a:ctrlId < 0)
        echo "CtrlID must be between 0 - 9"
        return
    end

    let contents = g:win_ctrl_buf_list[a:ctrlId]
    if type(l:contents) != v:t_list
        " Create the terminal
        terminal
        call SetBuffer(a:ctrlId)
    end
    let contents = g:win_ctrl_buf_list[a:ctrlId]
    if type(l:contents) != v:t_list
        echo "Unable to create a terminal or find the terminal's information."
    end

    let bufh = l:contents[1]
    call nvim_win_set_buf(0, l:bufh)
endfun

fun! SetBuffer(ctrlId)
    if has_key(b:, "terminal_job_id") == 0
        echo "You must be in a terminal to execute this command"
        return
    end
    if (a:ctrlId > 9) || (a:ctrlId < 0)
        echo "CtrlID must be between 0 - 3"
        return
    end

    let g:win_ctrl_buf_list[a:ctrlId] = [b:terminal_job_id, nvim_win_get_buf(0)]
endfun

fun! SendTerminalCommand(ctrlId, command)
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

    let job_id = l:contents[0]
    call chansend(l:job_id, a:command)
endfun




