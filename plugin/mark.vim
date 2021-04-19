augroup THE_PRIMEAGEN_HARPOON
    autocmd!
    autocmd BufLeave * :lua require('harpoon.mark').store_offset()
augroup END
