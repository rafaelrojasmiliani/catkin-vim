" Plugin initialization for catkin-vim

if exists('g:loaded_catkin_vim')
  finish
endif
let g:loaded_catkin_vim = 1
let g:is_catkin_workspace = 0


" Function to show a popup window with package selection
function! s:ShowPackageSelectionPopup()
  " Get the list of packages in the ROS workspace
  let l:packages = systemlist("catkin list -u --quiet")

  " Check if any packages were found
  if empty(l:packages)
    echo "No packages found in the workspace."
    return
  endif

  " Create a list where we will store the selected packages
  let l:selected_packages = map(copy(l:packages), {_, v -> v:true})


  " Prepare lines with checkboxes
  let l:lines = []
  for l:pkg in l:packages
    call add(l:lines,  l:pkg)
  endfor

  let s:ctx = {'select': 0, 'menu': l:lines, 'selected_packages': l:selected_packages, 'packages': l:packages}
  " Create the popup window with options
  let l:popup_options = {
        \ 'title': 'Select Packages',
        \ 'minwidth': 40,
        \ 'minheight': len(l:lines),
        \ 'cursorline': 0,
        \ 'filter': function('s:select_packages_menu_filter', [s:ctx]),
        \ 'border': [],
        \ 'mapping': 0,
        \ }

  let l:menu = copy(s:ctx.menu)

  " Iterate over the menu to modify each line based on selection and status
  for l:i in range(len(l:menu))
    " Determine if the current item is selected (highlighted)
    let l:indicator = (l:i == s:ctx.select) ? '-> ' : '   '
    let l:selected  = (s:ctx.selected_packages[l:i]) ? '[*]' : '[ ]'
    " Prepend the indicator (arrow or spaces) to the line
    let l:menu[l:i] = l:indicator .. l:selected .. l:menu[l:i]
  endfor
  " Open the popup window
  let s:wid = popup_create(l:menu, l:popup_options)

  " Key mappings for popup interaction
  nnoremap <buffer><silent> q :call popup_close(s:popup_id)<CR>
endfunction

function! s:select_packages_menu_update(wid, ctx) abort
  let l:buf = winbufnr(a:wid)
  let l:menu = copy(a:ctx.menu)

  " Iterate over the menu to modify each line based on selection and status
  for l:i in range(len(l:menu))
    " Determine if the current item is selected (highlighted)
    let l:indicator = (l:i == a:ctx.select) ? '-> ' : '   '
    let l:selected  = (a:ctx.selected_packages[l:i]) ? '[*]' : '[ ]'
    " Prepend the indicator (arrow or spaces) to the line
    let l:menu[l:i] = l:indicator .. l:selected .. l:menu[l:i]
  endfor

  call setbufline(l:buf, 1, l:menu)
endfunction


" Filter function for handling input in the popup window
function! s:select_packages_menu_filter(ctx, id, key)
  if a:key == "\<CR>" || a:key == " "
    let a:ctx.selected_packages[a:ctx.select] = !a:ctx.selected_packages[a:ctx.select]
    call s:select_packages_menu_update(s:wid, a:ctx)
    return 1
  elseif a:key == "q" || a:key == "\x1b"
    let l:selected_packages = filter(copy(a:ctx.packages), {i, _ -> a:ctx.selected_packages[i]})
    let l:command = "catkin config --buildlist " . join(l:selected_packages, " ")
    execute "Dispatch! " . l:command

    call popup_close(a:id)
    return 1
  elseif a:key == "j"
    let a:ctx.select += a:ctx.select ==# len(a:ctx.menu)-1 ? 0 : 1
    call s:select_packages_menu_update(s:wid, a:ctx)
    return 1
  elseif a:key == "k"
    let a:ctx.select -= a:ctx.select ==# 0 ? 0 : 1
    call s:select_packages_menu_update(s:wid, a:ctx)
    return 1
  endif
  return 0
endfunction


function! s:CatkinCCMake()
  " Get the list of packages in the ROS workspace
  let l:packages = systemlist("catkin list -u --quiet")

  " Check if any packages were found
  if empty(l:packages)
    echo "No packages found in the workspace."
    return
  endif
  let l:lines = []
  for l:pkg in l:packages
    call add(l:lines,  l:pkg)
  endfor

  let l:ctx = {'select': 0,  'packages': l:packages}
  let l:popup_options = {
        \ 'title': 'Select Package',
        \ 'minwidth': 40,
        \ 'filter': 'popup_filter_menu',
        \ 'border': [],
        \ 'mapping': 0,
        \ 'callback': function('s:select_package_callback', [l:ctx]),
        \ }

	call popup_menu(l:lines, l:popup_options)

  nnoremap <buffer><silent> q :call popup_close(s:popup_id)<CR>


endfunction

function! s:select_package_callback(ctx, id, result)
    if a:result == -1
        return
    endif
   let a:ctx.select = a:result
   let l:pkg =  a:ctx.packages[a:result - 1]
   let l:pkg_path = system('catkin locate -q -e ' . l:pkg)

    if v:shell_error == 0
        let l:cmd =  "terminal ++close ccmake -B build/" . l:pkg . " -S " . l:pkg_path
        exec l:cmd
    else
      echo "Failed to locate package " . l:pkg
    endif
  return 0
endfunction
" Function to compile selected packages
function! s:Build()
  " Ensure there are selected packages

    let &makeprg="catkin build --no-status -v -s"

  " Use dispatch or execute the command to build the selected packages
  execute "Make"

endfunction

function! s:CatkinInit() abort
  " Run 'catkin locate' to check if we're in a Catkin workspace
  execute "Dispatch! catkin init"

  " If the command succeeds, set the global variable
  if v:shell_error == 0
    let g:is_catkin_workspace = 1
    let &makeprg="catkin build --no-status -v -s"
  else
    let g:is_catkin_workspace = 0
  endif
endfunction

function! s:CatkinTest()
  " Ensure there are selected packages

    let &makeprg="catkin test --no-status -v -s"

  " Use dispatch or execute the command to build the selected packages
  execute "Make"

  let &makeprg="catkin build --no-status -v -s"

endfunction

command! CatkinSelectPackages call s:ShowPackageSelectionPopup()
command! CatkinBuild call s:Build()
command! CatkinInit call s:CatkinInit()
command! CatkinClean :Dispatch! catkin clean -y
command! CatkinPurge :Dispatch!  rm -rf build/ logs/ devel/ .catkin_tools/
command! CatkinCCMake call s:CatkinCCMake()
command! CatkinTest call s:CatkinTest()
