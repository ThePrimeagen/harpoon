augroup THE_PRIMEAGEN_HARPOON
    autocmd!
    autocmd BufLeave,VimLeave * :lua require('harpoon.mark').store_offset()
augroup END
