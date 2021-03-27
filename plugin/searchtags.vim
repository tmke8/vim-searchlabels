" sneak.vim - The missing motion
" Author:       Justin M. Keyes
" Version:      1.8
" License:      MIT

if exists('g:loaded_sneak_plugin') || &compatible || v:version < 700
  finish
endif
let g:loaded_sneak_plugin = 1

let s:cpo_save = &cpo
set cpo&vim

" Persist state for repeat.
"     opfunc    : &operatorfunc at g@ invocation.
"     opfunc_st : State during last 'operatorfunc' (g@) invocation.
let s:st = { 'rst':1, 'input':'', 'inputlen':0, 'reverse':0, 'bounds':[0,0],
      \'inclusive':0, 'label':'', 'opfunc':'', 'opfunc_st':{} }

if exists('##OptionSet')
  augroup sneak_optionset
    autocmd!
    autocmd OptionSet operatorfunc let s:st.opfunc = &operatorfunc | let s:st.opfunc_st = {}
  augroup END
endif

func! searchtags#init() abort
  unlockvar g:searchtags#opt
  "options                                 v-- for backwards-compatibility
  let g:searchtags#opt = { 'f_reset' : get(g:, 'searchtags#nextprev_f', get(g:, 'searchtags#f_reset', 1))
      \ ,'t_reset'      : get(g:, 'searchtags#nextprev_t', get(g:, 'searchtags#t_reset', 1))
      \ ,'s_next'       : get(g:, 'searchtags#s_next', 0)
      \ ,'absolute_dir' : get(g:, 'searchtags#absolute_dir', 0)
      \ ,'use_ic_scs'   : get(g:, 'searchtags#use_ic_scs', 0)
      \ ,'map_netrw'    : get(g:, 'searchtags#map_netrw', 1)
      \ ,'label'        : get(g:, 'searchtags#label', get(g:, 'searchtags#streak', 0)) && (v:version >= 703) && has("conceal")
      \ ,'label_esc'    : get(g:, 'searchtags#label_esc', get(g:, 'searchtags#streak_esc', "\<space>"))
      \ ,'prompt'       : get(g:, 'searchtags#prompt', '>')
      \ }

  for k in ['f', 't'] "if user mapped f/t to Sneak, then disable f/t reset.
    if maparg(k, 'n') =~# 'Sneak'
      let g:searchtags#opt[k.'_reset'] = 0
    endif
  endfor
  lockvar g:searchtags#opt
endf

call searchtags#init()

func! searchtags#state() abort
  return deepcopy(s:st)
endf

func! searchtags#is_sneaking() abort
  return exists("#searchtags#CursorMoved")
endf

func! searchtags#cancel() abort
  call searchtags#util#removehl()
  augroup sneak
    autocmd!
  augroup END
  if maparg('<esc>', 'n') =~# 'searchtags#cancel' "teardown temporary <esc> mapping
    silent! unmap <esc>
  endif
  return ''
endf


augroup sneakysneak
    au!
    au CmdlineLeave / call s:delayed_call(0)
    au CmdlineLeave \? call s:delayed_call(1)
augroup END

func! s:delayed_call(reverse) abort
    call timer_start(0, {-> searchtags#wrap('', a:reverse)})
endf

" Entrypoint for `s`.
func! searchtags#wrap(op, reverse) abort
  " get last search
  let input = @/
  let [cnt, reg] = [v:count1, v:register] "get count and register before doing _anything_, else they get overwritten.
  let inputlen = strchars(input)

  if exists('#User#SneakEnter')
    doautocmd <nomodeline> User SneakEnter
    redraw
  endif
  " highlight matches
  call searchtags#to(a:op, input, inputlen, cnt, reg, 0, a:reverse)
  if exists('#User#SneakLeave')
    doautocmd <nomodeline> User SneakLeave
  endif
endf

" Repeats the last motion.
func! s:rpt(op, reverse) abort
  if s:st.rst "reset by f/F/t/T
    exec "norm! ".(searchtags#util#isvisualop(a:op) ? "gv" : "").v:count1.(a:reverse ? "," : ";")
    return
  endif

  let l:relative_reverse = (a:reverse && !s:st.reverse) || (!a:reverse && s:st.reverse)
  call searchtags#to(a:op, s:st.input, s:st.inputlen, v:count1, v:register, 1,
        \ (g:searchtags#opt.absolute_dir ? a:reverse : l:relative_reverse), s:st.inclusive, 0)
endf

" input:      may be shorter than inputlen if the user pressed <enter> at the prompt.
" inclusive:  0: t-like, 1: f-like, 2: /-like
func! searchtags#to(op, input, inputlen, count, register, repeatmotion, reverse) abort "{{{
  let s = g:searchtags#search#instance
  call s.init(a:input, a:repeatmotion, a:reverse)

  let l:gt_lt = a:reverse ? '<' : '>'
  let bounds = a:repeatmotion ? s:st.bounds : [0,0] " [left_bound, right_bound]
  let l:scope_pattern = '' " pattern used to highlight the vertical 'scope'
  let l:match_bounds  = ''

  "scope to a column of width 2*(v:count1) _except_ for operators/repeat-motion/1-char-search
  if ((a:count > 1) || max(bounds))
    if !max(bounds) "derive bounds from count (_logical_ bounds highlighted in 'scope')
      let bounds[0] = max([0, (virtcol('.') - a:count - 1)])
      let bounds[1] = a:count + virtcol('.') + 1
    endif
    "Match *all* chars in scope. Use \%<42v (virtual column) instead of \%<42c (byte column).
    let l:scope_pattern .= '\%>'.bounds[0].'v\%<'.bounds[1].'v'
  endif

  if max(bounds)
    "adjust logical left-bound for the _match_ pattern by -length(s) so that if _any_
    "char is within the logical bounds, it is considered a match.
    let l:leftbound = max([0, (bounds[0] - a:inputlen) + 1])
    let l:match_bounds   = '\%>'.l:leftbound.'v\%<'.bounds[1].'v'
    let s.match_pattern .= l:match_bounds
  endif

  "TODO: refactor vertical scope calculation into search.vim,
  "      so this can be done in s.init() instead of here.
  call s.initpattern()

  let s:st.rptreverse = a:reverse
  if !a:repeatmotion "this is a new (not repeat) invocation
    "persist even if the search fails, because the _reverse_ direction might have a match.
    let s:st.rst = 0 | let s:st.input = a:input | let s:st.inputlen = a:inputlen
    let s:st.reverse = a:reverse | let s:st.bounds = bounds | let s:st.inclusive = 2
  endif

  "find out if there were matches
  let matchpos = s.dosearch()
  if 0 == max(matchpos)
    break
  endif

  if 0 == max(matchpos)
    let km = empty(&keymap) ? '' : ' ('.&keymap.' keymap)'
    call searchtags#util#echo('not found'.(max(bounds) ? printf(km.' (in columns %d-%d): %s', bounds[0], bounds[1], a:input) : km.': '.a:input))
    return
  endif
  "search succeeded

  call searchtags#util#removehl()

  let curlin = string(line('.'))
  let curcol = string(virtcol('.') + (a:reverse ? -1 : 1))

  "Might as well scope to window height (+/- 99).
  let l:top = max([0, line('w0')-99])
  let l:bot = line('w$')+99
  let l:restrict_top_bot = '\%'.l:gt_lt.curlin.'l\%>'.l:top.'l\%<'.l:bot.'l'
  let l:scope_pattern .= l:restrict_top_bot
  let s.match_pattern .= l:restrict_top_bot
  let curln_pattern  = l:match_bounds.'\%'.curlin.'l\%'.l:gt_lt.curcol.'v'

  "highlight the vertical 'tunnel' that the search is scoped-to
  if max(bounds) "perform the scoped highlight...
    let w:sneak_sc_hl = matchadd('SneakScope', l:scope_pattern)
  endif

  call s:attach_autocmds()

  "highlight actual matches at or below the cursor position
  "  - store in w: because matchadd() highlight is per-window.
  let w:sneak_hl_id = matchadd('Sneak',
        \ (s.prefix).(s.match_pattern).(s.search).'\|'.curln_pattern.(s.search))

  " Operators always invoke label-mode.
  " If a:label is a string set it as the target, without prompting.
  let label = ''
  let target = (!empty(label) || (s.hasmatches(1))) && !max(bounds)
        \ ? searchtags#label#to(s, 0, label) : ""

  if '' != target
    call searchtags#util#removehl()
  endif

endf "}}}

func! s:attach_autocmds() abort
  augroup sneak
    autocmd!
    autocmd InsertEnter,WinLeave,BufLeave * call searchtags#cancel()
    "_nested_ autocmd to skip the _first_ CursorMoved event.
    "NOTE: CursorMoved is _not_ triggered if there is typeahead during a macro/script...
    autocmd CursorMoved * autocmd sneak CursorMoved * call searchtags#cancel()
  augroup END
endf


onoremap <silent> <Plug>SneakRepeat :<c-u>call searchtags#wrap(v:operator, searchtags#util#getc(), searchtags#util#getc(), searchtags#util#getc(), searchtags#util#getc())<cr>

" repeat motion (explicit--as opposed to implicit 'clever-s')
nnoremap <silent> <Plug>Sneak_; :<c-u>call <SID>rpt('', 0)<cr>
nnoremap <silent> <Plug>Sneak_, :<c-u>call <SID>rpt('', 1)<cr>
xnoremap <silent> <Plug>Sneak_; :<c-u>call <SID>rpt(visualmode(), 0)<cr>
xnoremap <silent> <Plug>Sneak_, :<c-u>call <SID>rpt(visualmode(), 1)<cr>
onoremap <silent> <Plug>Sneak_; :<c-u>call <SID>rpt(v:operator, 0)<cr>
onoremap <silent> <Plug>Sneak_, :<c-u>call <SID>rpt(v:operator, 1)<cr>

if !hasmapto('<Plug>Sneak_;', 'n') && !hasmapto('<Plug>SneakNext', 'n') && mapcheck(';', 'n') ==# ''
  nmap ; <Plug>Sneak_;
  omap ; <Plug>Sneak_;
  xmap ; <Plug>Sneak_;
endif
if !hasmapto('<Plug>Sneak_,', 'n') && !hasmapto('<Plug>SneakPrevious', 'n')
  if mapcheck(',', 'n') ==# ''
    nmap , <Plug>Sneak_,
    omap , <Plug>Sneak_,
    xmap , <Plug>Sneak_,
  elseif mapcheck('\', 'n') ==# '' || mapcheck('\', 'n') ==# ','
    nmap \ <Plug>Sneak_,
    omap \ <Plug>Sneak_,
    xmap \ <Plug>Sneak_,
  endif
endif

if g:searchtags#opt.map_netrw && -1 != stridx(maparg("s", "n"), "Sneak")
  func! s:map_netrw_key(key) abort
    let expanded_map = maparg(a:key,'n')
    if !strlen(expanded_map) || expanded_map =~# '_Net\|FileBeagle'
      if strlen(expanded_map) > 0 "else, mapped to <nop>
        silent exe (expanded_map =~# '<Plug>' ? 'nmap' : 'nnoremap').' <buffer> <silent> <leader>'.a:key.' '.expanded_map
      endif
      "unmap the default buffer-local mapping to allow Sneak's global mapping.
      silent! exe 'nunmap <buffer> '.a:key
    endif
  endf

  augroup sneak_netrw
    autocmd!
    autocmd FileType netrw,filebeagle autocmd sneak_netrw CursorMoved <buffer>
          \ call <sid>map_netrw_key('s') | call <sid>map_netrw_key('S') | autocmd! sneak_netrw * <buffer>
  augroup END
endif


let &cpo = s:cpo_save
unlet s:cpo_save
