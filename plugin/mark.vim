fun! HarpoonLeave()
    lua require('harpoon.mark').store_offset()
    lua require('harpoon').save()
endfun

augroup THE_PRIMEAGEN_HARPOON
    autocmd!
    autocmd VimLeavePre * :call HarpoonLeave()
    autocmd BufLeave * :lua require('harpoon.mark').store_offset()
augroup END
