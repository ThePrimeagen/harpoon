syntax case ignore
" A file is anything except a `/` at the end of the string
syntax match HarpoonFile @[^/]\+$@

" A directory is anything that ends with a `/`
syntax match HarpoonDirectory @^.\+/@

highlight default link HarpoonDirectory Directory

