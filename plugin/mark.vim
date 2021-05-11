" Should we do a lua version?
" Challenge they must require harpoon
augroup THE_PRIMEAGEN_HARPOON
    autocmd!
    autocmd BufLeave,VimLeave * :lua require('harpoon.mark').store_offset()
    autocmd VimEnter * :lua require('harpoon.ui').nav_on_open()
augroup END
