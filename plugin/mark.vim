augroup THE_PRIMEAGEN_HARPOON
    autocmd!
    autocmd VimLeave * :lua require('harpoon').save()
    autocmd BufLeave * :lua require('harpoon.mark').store_offset()
augroup END
