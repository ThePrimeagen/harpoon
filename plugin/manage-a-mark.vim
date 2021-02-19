augroup THE_PRIMEAGEN_HARPOON
    autocmd!
    autocmd VimLeave * :lua require('harpoon.manage-a-mark').save()
    autocmd BufLeave * :lua require('harpoon.manage-a-mark').store_offset()
augroup END
