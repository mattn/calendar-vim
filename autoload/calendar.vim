let g:calendar_action = get(g:, 'calendar_action', 'calendar#diary')
let g:calendar_sign = get(g:, 'calendar_sign', 'calendar#sign')

if index(['left', 'left-fit', 'right'], get(g:, 'calendar_mark', '')) < 0
  let g:calendar_mark = 'left'
endif
if index(['top', 'bottom', 'both', ''], get(g:, 'calendar_navi', '!')) < 0
  let g:calendar_navi = 'top'
endif

let g:calendar_navi_label = get(g:, 'calendar_navi_label', 'Prev,Today,Next')
let g:calendar_diary_list_curr_idx = get(g:, 'calendar_diary_list_curr_idx', 0)

if !exists("g:calendar_diary")
  if exists("g:calendar_diary_list") && len(g:calendar_diary_list) > 0 && g:calendar_diary_list_curr_idx >= 0 && g:calendar_diary_list_curr_idx < len(g:calendar_diary_list)
    let g:calendar_diary = g:calendar_diary_list[g:calendar_diary_list_curr_idx].path
    let g:calendar_diary_extension = g:calendar_diary_list[g:calendar_diary_list_curr_idx].ext
  else
    let g:calendar_diary = "~/diary"
  endif
endif

let g:calendar_focus_today = get(g:, 'calendar_focus_today', 0)

if index(['', 'title', 'statusline'], get(g:, 'calendar_datetime', '!')) < 0
  let g:calendar_datetime = 'title'
endif

if !exists("g:calendar_options")
  let g:calendar_options = "fdc=0 nonu"
  if has("+relativenumber") || exists("+relativenumber")
    let g:calendar_options .= " nornu"
  endif
endif

let g:calendar_filetype = get(g:, 'calendar_filetype', 'markdown')
let g:calendar_diary_extension = get(g:, 'calendar_diary_extension', '.md')
let g:calendar_search_grepprg = get(g:, 'calendar_search_grepprg', 'grep')
"*****************************************************************
"* Month data: [days, day-of-year offset, short name]
"*****************************************************************
let s:month_days   = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
let s:month_params = [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
let s:month_names  = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     \ 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

"*****************************************************************
"* Default Calendar key bindings
"*****************************************************************
let s:calendar_keys = {
\ 'close'           : 'q',
\ 'do_action'       : '<CR>',
\ 'goto_today'      : 't',
\ 'show_help'       : '?',
\ 'redisplay'       : 'r',
\ 'goto_next_month' : '<RIGHT>',
\ 'goto_prev_month' : '<LEFT>',
\ 'goto_next_year'  : '<UP>',
\ 'goto_prev_year'  : '<DOWN>',
\}

if exists("g:calendar_keys") && type(g:calendar_keys) == 4
  let s:calendar_keys = extend(s:calendar_keys, g:calendar_keys)
end

"*****************************************************************
"* CalendarClose : close the calendar
"*----------------------------------------------------------------
"*****************************************************************
function! calendar#close(...) abort
  bw!
endfunction

"*****************************************************************
"* format_weeknm : format week number string
"*****************************************************************
function! s:format_weeknm(weeknm, viweek) abort
  let l:prefix = (a:weeknm <= 2) ? 'WK' : (a:weeknm <= 4) ? 'KW' : ''
  if a:weeknm == 5
    return printf('%2d', a:viweek)
  endif
  let l:fmt = (a:weeknm % 2 == 1) ? '%02d' : '%2d'
  return l:prefix . printf(l:fmt, a:viweek)
endfunction

"*****************************************************************
"* CalendarDoAction : call the action handler function
"*----------------------------------------------------------------
"*****************************************************************
function! calendar#action(...) abort
  let l:text = getline(".")
  if l:text =~ "^( )"
    let l:list_idx = 0
    let l:curl = line(".") - 1
    while l:curl>1
      if getline(l:curl) =~ "^([\* ])"
        let l:list_idx += 1
        let l:curl -= 1
      else
        let g:calendar_diary_list_curr_idx = l:list_idx
        let g:calendar_diary = g:calendar_diary_list[l:list_idx].path
        let g:calendar_diary_extension = g:calendar_diary_list[l:list_idx].ext
        call calendar#show(b:CalendarDir, b:CalendarYear, b:CalendarMonth)
        return
      endif
    endwhile
  endif

  if exists('g:calendar_navi')
    let l:navi = (a:0 > 0)? a:1 : expand("<cWORD>")
    let l:curl = line(".")
    let l:curp = getpos(".")
    if l:navi == '<' . get(split(g:calendar_navi_label, ','), 0, '')
      if b:CalendarMonth > 1
        call calendar#show(b:CalendarDir, b:CalendarYear, b:CalendarMonth-1)
      else
        call calendar#show(b:CalendarDir, b:CalendarYear-1, 12)
      endif
    elseif l:navi == get(split(g:calendar_navi_label, ','), 2, '') . '>'
      if b:CalendarMonth < 12
        call calendar#show(b:CalendarDir, b:CalendarYear, b:CalendarMonth+1)
      else
        call calendar#show(b:CalendarDir, b:CalendarYear+1, 1)
      endif
    elseif l:navi == get(split(g:calendar_navi_label, ','), 1, '')
      call calendar#show(b:CalendarDir)
      if exists('g:calendar_today')
        exe "call " . g:calendar_today . "()"
      endif
    elseif l:navi == 'NextYear'
      call calendar#show(b:CalendarDir, b:CalendarYear + 1, b:CalendarMonth)
      call setpos('.', l:curp)
      return
    elseif l:navi == 'PrevYear'
      call calendar#show(b:CalendarDir, b:CalendarYear - 1, b:CalendarMonth)
      call setpos('.', l:curp)
      return
    else
      let l:navi = ''
    endif
    if l:navi != ''
      if g:calendar_focus_today == 1 && search("\*","w") > 0
        silent execute "normal! gg/\*\<cr>"
        return
      else
        if l:curl < line('$')/2
          silent execute "normal! gg0/".l:navi."\<cr>"
        else
          silent execute "normal! G$?".l:navi."\<cr>"
        endif
        return
      endif
    endif
  endif

  if !exists("g:calendar_action") || g:calendar_action == ""
    return
  endif

  if b:CalendarDir == 0 || b:CalendarDir == 3
    let l:dir = 'V'
    let l:cnr = 1
    let l:week = ((col(".")+1) / 3) - 1
  elseif b:CalendarDir == 1
    let l:dir = 'H'
    if exists('g:calendar_weeknm')
      let l:cnr = col('.') - (col('.')%(24+5)) + 1
    else
      let l:cnr = col('.') - (col('.')%(24)) + 1
    endif
    let l:week = ((col(".") - l:cnr - 1 + l:cnr/49) / 3)
  elseif b:CalendarDir == 2
    let l:dir = 'T'
    let l:cnr = 1
    let l:week = ((col(".")+1) / 3) - 1
  endif
  let l:lnr = 1
  let l:hdr = 1
  while 1
    if l:lnr > line('.')
      break
    endif
    let l:sline = getline(l:lnr)
    if l:sline =~ '^\s*$'
      let l:hdr = l:lnr + 1
    endif
    let l:lnr = l:lnr + 1
  endwhile
  let l:lnr = line('.')
  if exists('g:calendar_monday')
      let l:week = l:week + 1
  elseif l:week == 0
      let l:week = 7
  endif
  if l:lnr-l:hdr < 2
    return
  endif
  let l:sline = substitute(strpart(getline(l:hdr),l:cnr,21),'\s*\(.*\)\s*','\1','')
  if b:CalendarDir != 2
    if (col(".")-l:cnr) > 21
      return
    endif

    if g:calendar_mark == 'right' && col('.') > 1
      normal! h
      let l:day = matchstr(expand("<cword>"), '[^0].*')
      normal! l
    else
      let l:day = matchstr(expand("<cword>"), '[^0].*')
    endif
  else
    let l:c = col('.')
    let l:day = ''
    let l:lnum = line('.')
    let l:cursorchar = getline(l:lnum)[col('.') - 1]
    while l:day == '' && l:lnum > 2 && l:cursorchar != '-' && l:cursorchar != '+'
      let l:day = matchstr(getline(l:lnum), '^.*|\zs[^|]\{-}\%'.l:c.'c[^|]\{-}\ze|.*$')
      let l:day = matchstr(l:day, '\d\+')
      let l:lnum = l:lnum - 1
      let l:cursorchar = getline(l:lnum)[col('.') - 1]
    endwhile
  endif
  if l:day == 0
    return
  endif
  if exists('g:calendar_erafmt') && g:calendar_erafmt !~ "^\s*$"
    let l:year = matchstr(substitute(l:sline, '/.*', '', ''), '\d\+')
    let l:month = matchstr(substitute(l:sline, '.*/\(\d\d\=\).*', '\1', ""), '[^0].*')
    if g:calendar_erafmt =~ '.*,[+-]*\d\+'
      let l:veranum = substitute(g:calendar_erafmt,'.*,\([+-]*\d\+\)','\1','')
      if l:year-l:veranum > 0
        let l:year = l:year-l:veranum
      endif
    endif
  else
    let l:year  = matchstr(substitute(l:sline, '/.*', '', ''), '[^0].*')
    let l:month = matchstr(substitute(l:sline, '\d*/\(\d\d\=\).*', '\1', ""), '[^0].*')
  endif
  exe "call " . g:calendar_action . "(l:day, l:month, l:year, l:week, l:dir)"
endfunction

"*****************************************************************
"* Calendar : build calendar
"*----------------------------------------------------------------
"*   a1 : direction
"*   a2 : month(if given a3, it's year)
"*   a3 : if given, it's month
"*****************************************************************
function! calendar#show(...) abort

  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  "+++ ready for build
  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  let l:vtoday = strftime('%Y').strftime('%m').strftime('%d')

  if a:0 == 0
    let l:dir = 0
    let l:vyear = strftime('%Y')
    let l:vmnth = matchstr(strftime('%m'), '[^0].*')
  elseif a:0 == 1
    let l:dir = a:1
    let l:vyear = strftime('%Y')
    let l:vmnth = matchstr(strftime('%m'), '[^0].*')
  elseif a:0 == 2
    let l:dir = a:1
    let l:vyear = strftime('%Y')
    let l:vmnth = matchstr(a:2, '^[^0].*')
  else
    let l:dir = a:1
    let l:vyear = a:2
    let l:vmnth = matchstr(a:3, '^[^0].*')
  endif

  let l:vmnth_org = l:vmnth
  let l:vyear_org = l:vyear

  if l:dir != 2
    let l:vmnth = l:vmnth - 1
    if l:vmnth < 1
      let l:vmnth = 12
      let l:vyear = l:vyear - 1
    endif
  endif

  let l:vdisplay1 = ''
  let l:vheight = 1
  let l:vmcnt = 0

  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  "+++ build display
  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  if exists("g:calendar_begin")
    exe "call " . g:calendar_begin . "()"
  endif
  if l:dir == 2
    let l:vmcntmax = 1
    let l:whitehrz = ''
    if !exists('b:CalendarDir') && !(bufname('%') == '' && &l:modified == 0)
      let l:width = &columns
      let l:height = &lines - 2
    else
      let l:width = winwidth(0)
      let l:height = winheight(0)
    endif
    let l:hrz = max([l:width / 8 - 5, 0])
    let l:whitehrz = repeat(' ', l:hrz) . '|'
    let l:navifix = (exists('g:calendar_navi') && g:calendar_navi == 'both') * 2
    let l:vrt = (l:height - &cmdheight - 3 - l:navifix) / 6 - 2
    if l:vrt < 0
      let l:vrt = 0
    endif
    if l:whitehrz == '|'
      let l:whitevrta = l:whitehrz
    else
      let l:whitevrta = l:whitehrz[1:]
    endif
    let l:leftmargin = (l:width - (strlen(l:whitehrz) + 3) * 7 - 1) / 2
    let l:whiteleft = repeat(' ', l:leftmargin)
    let l:vrt_row = "\n" . l:whiteleft . '|' . repeat('   ' . l:whitehrz, 7)
    let l:whitevrt = repeat(l:vrt_row, l:vrt) . "\n"
    let l:borderhrz = '---'.substitute(substitute(l:whitehrz, ' ', '-', 'g'), '|', '+', '')
    let l:whitevrt2 = l:whiteleft . '+' . repeat(l:borderhrz, 7)
    let l:whitevrtweeknm = l:whitevrt.l:whitevrt2."\n"
    let l:whitevrt = l:whitevrta.l:whitevrt.l:whitevrt2."\n"
    let l:fridaycol = (strlen(l:whitehrz) + 3) * 5 + strlen(l:whiteleft) + 1
    let l:saturdaycol = (strlen(l:whitehrz) + 3) * 6 + strlen(l:whiteleft) + 1
  else
    let l:vmcntmax = get(g:, 'calendar_number_of_months', 3)
  endif
  while l:vmcnt < l:vmcntmax
    let l:vcolumn = 22
    let l:vnweek = -1
    "--------------------------------------------------------------
    "--- calculating
    "--------------------------------------------------------------
    if l:vmnth < 1 || l:vmnth > 12
      echo 'Invalid Year or Month'
      return
    endif
    let l:vmdays = s:month_days[l:vmnth - 1]
    let l:vparam = s:month_params[l:vmnth - 1]
    let l:vsmnth = s:month_names[l:vmnth - 1]
    let l:vleap = (l:vyear % 4 == 0 && l:vyear % 100 != 0) || l:vyear % 400 == 0
    if l:vleap
      if l:vmnth == 2
        let l:vmdays = 29
      elseif l:vmnth >= 3
        let l:vparam = l:vparam + 1
      endif
    endif

    if l:vnweek == -1
      let l:vnweek = ( l:vyear * 365 ) + l:vparam
      let l:vnweek = l:vnweek + ( l:vyear/4 ) - ( l:vyear/100 ) + ( l:vyear/400 )
      if l:vleap
        let l:vnweek = l:vnweek - 1
      endif
      let l:vnweek = l:vnweek - 1
    endif

    if l:vyear <= 1752
      let l:vnweek = l:vnweek - 3
    endif

    let l:vnweek = l:vnweek % 7

    if exists('g:calendar_monday')
      if l:vnweek == 0
        let l:vnweek = 7
      endif
      let l:vnweek = l:vnweek - 1
    endif

    if exists('g:calendar_weeknm')

      let l:vnweek_iso = l:vnweek
      if !exists('g:calendar_monday')
        let l:vnweek_iso = (l:vnweek + 6) % 7
      endif
      let l:vfweek =((l:vparam % 7)  -l:vnweek_iso+ 14-2) % 7
      let l:viweek = (l:vparam - l:vfweek-2+7 ) / 7 +1

      if l:vfweek < 3
         let l:viweek = l:viweek - 1
      endif

      let l:vfweekl = 52
      if l:vfweek == 3 || (l:vfweek == 4 && l:vleap)
        let l:vfweekl = 53
      endif

      if l:viweek == 0
        let l:viweek = 52
        let l:vleap = ((l:vyear-1) % 4 == 0 &&
              \ ((l:vyear-1) % 100 != 0 || (l:vyear-1) % 400 == 0))
        if l:vfweek == 2 || (l:vfweek == 1 && l:vleap)
          let l:viweek = 53
        endif
      endif

      let l:vcolumn = l:vcolumn + 5
      if g:calendar_weeknm == 5
        let l:vcolumn = l:vcolumn - 2
      endif
    endif

    "--------------------------------------------------------------
    "--- displaying
    "--------------------------------------------------------------
    let l:vdisplay2 = l:vyear.'/'.l:vmnth.'('
    if exists('g:calendar_erafmt') && g:calendar_erafmt !~ "^\s*$"
          \ && g:calendar_erafmt =~ '.*,[+-]*\d\+'
      let l:veranum = substitute(g:calendar_erafmt,'.*,\([+-]*\d\+\)','\1','')
      if l:vyear+l:veranum > 0
        let l:vdisplay2 = substitute(g:calendar_erafmt,'\(.*\),.*','\1','')
              \ .(l:vyear+l:veranum).'/'.l:vmnth.'('
      endif
    endif
    let l:vdisplay2 = repeat(' ', max([(l:vcolumn-strlen(l:vdisplay2))/2-2, 0])).l:vdisplay2
    let l:mname = (exists('g:calendar_mruler') && g:calendar_mruler !~ "^\s*$")
          \ ? get(split(g:calendar_mruler, ','), l:vmnth-1, '') : l:vsmnth
    let l:vdisplay2 = l:vdisplay2 . l:mname . ')' . "\n"
    let l:vwruler = "Su Mo Tu We Th Fr Sa"
    if exists('g:calendar_wruler') && g:calendar_wruler !~ "^\s*$"
      let l:vwruler = g:calendar_wruler
    endif
    if exists('g:calendar_monday')
      let l:vwruler = strpart(l:vwruler,stridx(l:vwruler, ' ') + 1).' '.strpart(l:vwruler,0,stridx(l:vwruler, ' '))
    endif
    if l:dir == 2
      let l:whiteruler = substitute(substitute(l:whitehrz, ' ', '_', 'g'), '__', '  ', '')
      let l:vwruler = '| '.substitute(l:vwruler, ' ', l:whiteruler.' ', 'g').l:whiteruler
      let l:vdisplay2 = l:vdisplay2.l:whiteleft.l:vwruler."\n"
    else
      let l:vdisplay2 = l:vdisplay2.' '.l:vwruler."\n"
    endif
    if g:calendar_mark == 'right' && l:dir != 2
      let l:vdisplay2 = l:vdisplay2.' '
    endif

    " build calendar
    let l:vinpcur = 0
    while (l:vinpcur < l:vnweek)
      if l:dir == 2
        if l:vinpcur % 7
          let l:vdisplay2 = l:vdisplay2.l:whitehrz
        else
          let l:vdisplay2 = l:vdisplay2.l:whiteleft.'|'
        endif
      endif
      let l:vdisplay2 = l:vdisplay2.'   '
      let l:vinpcur = l:vinpcur + 1
    endwhile
    let l:vdaycur = 1
    while (l:vdaycur <= l:vmdays)
      if l:dir == 2
        if l:vinpcur % 7
          let l:vdisplay2 = l:vdisplay2.l:whitehrz
        else
          let l:vdisplay2 = l:vdisplay2.l:whiteleft.'|'
        endif
      endif
      let l:vtarget = printf('%d%02d%02d', l:vyear, l:vmnth, l:vdaycur)
      if exists("g:calendar_sign") && g:calendar_sign != ""
        exe "let l:vsign = " . g:calendar_sign . "(l:vdaycur, l:vmnth, l:vyear)"
        if l:vsign != ""
          let l:vsign = l:vsign[0]
          if l:vsign !~ "[+!#$%&@?]"
            let l:vsign = "+"
          endif
        endif
      else
        let l:vsign = ''
      endif

      " show mark
      if g:calendar_mark == 'right'
        if l:vdaycur < 10
          let l:vdisplay2 = l:vdisplay2.' '
        endif
        let l:vdisplay2 = l:vdisplay2.l:vdaycur
      elseif g:calendar_mark == 'left-fit'
        if l:vdaycur < 10
          let l:vdisplay2 = l:vdisplay2.' '
        endif
      endif
      if l:vtarget == l:vtoday
        let l:vdisplay2 = l:vdisplay2.'*'
      elseif l:vsign != ''
        let l:vdisplay2 = l:vdisplay2.l:vsign
      else
        let l:vdisplay2 = l:vdisplay2.' '
      endif
      if g:calendar_mark == 'left'
        if l:vdaycur < 10
          let l:vdisplay2 = l:vdisplay2.' '
        endif
        let l:vdisplay2 = l:vdisplay2.l:vdaycur
      endif
      if g:calendar_mark == 'left-fit'
        let l:vdisplay2 = l:vdisplay2.l:vdaycur
      endif
      let l:vdaycur = l:vdaycur + 1

      " fix Gregorian
      if l:vyear == 1752 && l:vmnth == 9 && l:vdaycur == 3
        let l:vdaycur = 14
      endif

      let l:vinpcur = l:vinpcur + 1
      if l:vinpcur % 7 == 0
        if exists('g:calendar_weeknm')
          if l:dir == 2
            let l:vdisplay2 = l:vdisplay2.l:whitehrz
          endif
          if g:calendar_mark != 'right'
            let l:vdisplay2 = l:vdisplay2.' '
          endif
          let l:vdisplay2 = l:vdisplay2 . s:format_weeknm(g:calendar_weeknm, l:viweek)
          let l:viweek = l:viweek + 1

          if l:viweek > l:vfweekl
            let l:viweek = 1
          endif

        endif
        let l:vdisplay2 = l:vdisplay2."\n"
        if g:calendar_mark == 'right' && l:dir != 2
          let l:vdisplay2 = l:vdisplay2.' '
        endif
      endif
    endwhile

    " if it is needed, fill with space
    if l:vinpcur % 7
      while (l:vinpcur % 7 != 0)
        if l:dir == 2
          let l:vdisplay2 = l:vdisplay2.l:whitehrz
        endif
        let l:vdisplay2 = l:vdisplay2.'   '
        let l:vinpcur = l:vinpcur + 1
      endwhile
      if exists('g:calendar_weeknm')
        if l:dir == 2
          let l:vdisplay2 = l:vdisplay2.l:whitehrz
        endif
        if g:calendar_mark != 'right'
          let l:vdisplay2 = l:vdisplay2.' '
        endif
        let l:vdisplay2 = l:vdisplay2 . s:format_weeknm(g:calendar_weeknm, l:viweek)
      endif
    endif

    " build display
    let l:vstrline = ''
    if l:dir == 1
      " for horizontal
      "--------------------------------------------------------------
      " +---+   +---+   +------+
      " |   |   |   |   |      |
      " | 1 | + | 2 | = |  1'  |
      " |   |   |   |   |      |
      " +---+   +---+   +------+
      "--------------------------------------------------------------
      let l:vtokline = 1
      while 1
        let l:vtoken1 = get(split(l:vdisplay1, "\n"), l:vtokline-1, '')
        let l:vtoken2 = get(split(l:vdisplay2, "\n"), l:vtokline-1, '')
        if l:vtoken1 == '' && l:vtoken2 == ''
          break
        endif
        while strlen(l:vtoken1) < (l:vcolumn+1)*l:vmcnt
          if strlen(l:vtoken1) % (l:vcolumn+1) == 0
            let l:vtoken1 = l:vtoken1.'|'
          else
            let l:vtoken1 = l:vtoken1.' '
          endif
        endwhile
        let l:vstrline = l:vstrline.l:vtoken1.'|'.l:vtoken2.' '."\n"
        let l:vtokline = l:vtokline + 1
      endwhile
      let l:vdisplay1 = l:vstrline
      let l:vheight = l:vtokline-1
    elseif (l:dir == 0 || l:dir == 3)
      " for vertical
      "--------------------------------------------------------------
      " +---+   +---+   +---+
      " | 1 | + | 2 | = |   |
      " +---+   +---+   | 1'|
      "                 |   |
      "                 +---+
      "--------------------------------------------------------------
      let l:vtokline = 1
      while 1
        let l:vtoken1 = get(split(l:vdisplay1, "\n"), l:vtokline-1, '')
        if l:vtoken1 == ''
          break
        endif
        let l:vstrline = l:vstrline.l:vtoken1."\n"
        let l:vtokline = l:vtokline + 1
        let l:vheight = l:vheight + 1
      endwhile
      if l:vstrline != ''
        let l:vstrline = l:vstrline.' '."\n"
        let l:vheight = l:vheight + 1
      endif
      let l:vtokline = 1
      while 1
        let l:vtoken2 = get(split(l:vdisplay2, "\n"), l:vtokline-1, '')
        if l:vtoken2 == ''
          break
        endif
        while strlen(l:vtoken2) < l:vcolumn
          let l:vtoken2 = l:vtoken2.' '
        endwhile
        let l:vstrline = l:vstrline.l:vtoken2."\n"
        let l:vtokline = l:vtokline + 1
        let l:vheight = l:vtokline + 1
      endwhile
      let l:vdisplay1 = l:vstrline
    else
      let l:vtokline = 1
      while 1
        let l:vtoken1 = get(split(l:vdisplay1, "\n"), l:vtokline-1, '')
        let l:vtoken2 = get(split(l:vdisplay2, "\n"), l:vtokline-1, '')
        if l:vtoken1 == '' && l:vtoken2 == ''
          break
        endif
        while strlen(l:vtoken1) < (l:vcolumn+1)*l:vmcnt
          if strlen(l:vtoken1) % (l:vcolumn+1) == 0
            let l:vtoken1 = l:vtoken1.'|'
          else
            let l:vtoken1 = l:vtoken1.' '
          endif
        endwhile
        if l:vtokline > 2
          if exists('g:calendar_weeknm')
            let l:vright = l:whitevrtweeknm
          elseif l:whitehrz == '|'
            let l:vright = l:whitevrt
          else
            let l:vright = ' '.l:whitevrt
          endif
        else
          let l:vright = "\n"
        endif
        let l:vstrline = l:vstrline.l:vtoken1.l:vtoken2.l:vright
        let l:vtokline = l:vtokline + 1
      endwhile
      let l:vdisplay1 = l:vstrline
      let l:vheight = l:vtokline-1
    endif
    let l:vmnth = l:vmnth + 1
    let l:vmcnt = l:vmcnt + 1
    if l:vmnth > 12
      let l:vmnth = 1
      let l:vyear = l:vyear + 1
    endif
  endwhile
  if exists("g:calendar_end")
    exe "call " . g:calendar_end . "()"
  endif
  if a:0 == 0
    return l:vdisplay1
  endif

  if exists("g:calendar_diary_list") && len(g:calendar_diary_list) > 0
    let l:vdisplay1 = l:vdisplay1 . "\nCalendars:\n" . repeat("-", l:vcolumn)
    let l:diary_index = 0
    for l:diary in g:calendar_diary_list
      if l:diary_index == g:calendar_diary_list_curr_idx
        let l:diary_list = "(*) " . l:diary["name"]
        let l:diary_list = "\n" . l:diary_list . repeat(" ", l:vcolumn-len(l:diary_list))
      else
        let l:diary_list = "( ) " . l:diary["name"]
        let l:diary_list = "\n" . l:diary_list . repeat(" ", l:vcolumn-len(l:diary_list))
      endif
      let l:vdisplay1 = l:vdisplay1 . l:diary_list
      let l:diary_index = l:diary_index + 1
    endfor
  endif

  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  "+++ build window
  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  let l:vwinnum = bufnr('__Calendar')
  if getbufvar(l:vwinnum, 'Calendar') == 'Calendar'
    let l:vwinnum = bufwinnr(l:vwinnum)
  else
    let l:vwinnum = -1
  endif

  if l:vwinnum >= 0
    if l:vwinnum != bufwinnr('%')
      exe l:vwinnum . 'wincmd w'
    endif
    setlocal modifiable
    silent %d _
  else
    if g:calendar_datetime == "title" && (!exists('s:bufautocommandsset'))
      auto BufEnter *Calendar let b:sav_titlestring = &titlestring | let &titlestring = '%{strftime("%c")}'
      auto BufLeave *Calendar if exists('b:sav_titlestring') | let &titlestring = b:sav_titlestring | endif
      let s:bufautocommandsset = 1
    endif

    if exists('g:calendar_navi') && l:dir
      if g:calendar_navi == 'both'
        let l:vheight = l:vheight + 4
      else
        let l:vheight = l:vheight + 2
      endif
    endif

    if l:dir == 1
      silent execute 'bo '.l:vheight.'split __Calendar'
      setlocal winfixheight
    elseif l:dir == 0
      silent execute 'to '.l:vcolumn.'vsplit __Calendar'
      setlocal winfixwidth
    elseif l:dir == 3
      silent execute 'bo '.l:vcolumn.'vsplit __Calendar'
      setlocal winfixwidth
    elseif bufname('%') == '' && &l:modified == 0
      silent execute 'edit __Calendar'
    else
      silent execute 'tabnew __Calendar'
    endif
    call s:CalendarBuildKeymap(l:dir, l:vyear, l:vmnth)
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete
    silent! exe "setlocal " . g:calendar_options
    let l:nontext_columns = &foldcolumn + &nu * &numberwidth
    if has("+relativenumber") || exists("+relativenumber")
      let l:nontext_columns += &rnu * &numberwidth
    endif
    setlocal nowrap
    setlocal norightleft
    setlocal modifiable
    setlocal nolist
    let b:Calendar = 'Calendar'
    setlocal filetype=calendar
    if l:dir != 2
      exe l:vcolumn + l:nontext_columns . "wincmd |"
    endif
  endif
  if g:calendar_datetime == "statusline"
    setlocal statusline=%{strftime('%c')}
  endif
  let b:CalendarDir = l:dir
  let b:CalendarYear = l:vyear_org
  let b:CalendarMonth = l:vmnth_org

  " navi
  if exists('g:calendar_navi')
    let l:navi_label = '<'
        \.get(split(g:calendar_navi_label, ','), 0, '').' '
        \.get(split(g:calendar_navi_label, ','), 1, '').' '
        \.get(split(g:calendar_navi_label, ','), 2, '').'>'
    if l:dir == 1
      let l:navcol = l:vcolumn + (l:vcolumn-strlen(l:navi_label)+2)/2
    elseif (l:dir == 0 || l:dir == 3)
      let l:navcol = (l:vcolumn-strlen(l:navi_label)+2)/2
    else
      let l:navcol = (l:width - strlen(l:navi_label)) / 2
    endif
    if l:navcol < 3
      let l:navcol = 3
    endif

    if g:calendar_navi == 'top'
      execute "normal gg".l:navcol."i "
      silent exec "normal! a".l:navi_label."\<cr>\<cr>"
      silent put! =l:vdisplay1
    endif
    if g:calendar_navi == 'bottom'
      silent put! =l:vdisplay1
      silent exec "normal! Gi\<cr>"
      execute "normal ".l:navcol."i "
      silent exec "normal! a".l:navi_label
    endif
    if g:calendar_navi == 'both'
      execute "normal gg".l:navcol."i "
      silent exec "normal! a".l:navi_label."\<cr>\<cr>"
      silent put! =l:vdisplay1
      silent exec "normal! Gi\<cr>"
      execute "normal ".l:navcol."i "
      silent exec "normal! a".l:navi_label
    endif
  else
    silent put! =l:vdisplay1
  endif

  setlocal nomodifiable
  stopinsert

  let l:vyear = l:vyear_org
  let l:vmnth = l:vmnth_org

  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  "+++ build highlight
  "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  call s:build_highlight(l:dir, l:vwruler,
        \ get(l:, 'fridaycol', 0), get(l:, 'saturdaycol', 0),
        \ get(l:, 'borderhrz', ''), get(l:, 'whiteleft', ''))

  return ''
endfunction

"*****************************************************************
"* build_highlight : set up syntax highlighting for calendar
"*****************************************************************
function! s:build_highlight(dir, vwruler, fridaycol, saturdaycol, borderhrz, whiteleft) abort
  syn clear
  if g:calendar_mark =~ 'left-fit'
    syn match CalToday display "\s*\*\d*"
    syn match CalMemo display "\s*[+!#$%&@?]\d*"
  elseif g:calendar_mark =~ 'right'
    syn match CalToday display "\d*\*\s*"
    syn match CalMemo display "\d*[+!#$%&@?]\s*"
  else
    syn match CalToday display "\*\s*\d*"
    syn match CalMemo display "[+!#$%&@?]\s*\d*"
  endif
  syn match CalHeader display "[^ ]*\d\+\/\d\+([^)]*)"

  if exists('g:calendar_navi')
    let l:navi_parts = split(g:calendar_navi_label, ',')
    exec "silent! syn match CalNavi display \"\\(<"
        \.get(l:navi_parts, 0, '')."\\|"
        \.get(l:navi_parts, 2, '').">\\)\""
    exec "silent! syn match CalNavi display \"\\s"
        \.get(l:navi_parts, 1, '')."\\s\"hs=s+1,he=e-1"
  endif

  " saturday, sunday
  if exists('g:calendar_monday')
    if a:dir == 1
      syn match CalSaturday display /|.\{15}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
      syn match CalSunday display /|.\{18}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
    elseif a:dir == 0 || a:dir == 3
      syn match CalSaturday display /^.\{15}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
      syn match CalSunday display /^.\{18}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
    else
      exec printf('syn match CalSaturday display /^.\{%d}\s\?\([0-9\ ]\d\)/hs=e-1 contains=ALL', a:fridaycol)
      exec printf('syn match CalSunday display /^.\{%d}\s\?\([0-9\ ]\d\)/hs=e-1 contains=ALL', a:saturdaycol)
    endif
  else
    if a:dir == 1
      syn match CalSaturday display /|.\{18}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
      syn match CalSunday display /|\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
    elseif a:dir == 0 || a:dir == 3
      syn match CalSaturday display /^.\{18}\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
      syn match CalSunday display /^\s\([0-9\ ]\d\)/hs=e-1 contains=ALL
    else
      exec printf('syn match CalSaturday display /^.\{%d}\s\?\([0-9\ ]\d\)/hs=e-1 contains=ALL', a:saturdaycol)
      syn match CalSunday display /^\s*|\s*\([0-9\ ]\d\)/hs=e-1 contains=ALL
    endif
  endif

  syn match CalCurrList display "^(\*).*$"

  if !exists('g:calendar_weeknm') || g:calendar_weeknm <= 2
    syn match CalWeeknm display "WK[0-9\ ]\d"
  else
    syn match CalWeeknm display "KW[0-9\ ]\d"
  endif

  execute 'syn match CalRuler "'.a:vwruler.'"'

  if search("\*","w") > 0
    silent execute "normal! gg/\*\<cr>"
  endif

  if a:dir == 2
    exec "syn match CalNormal display " string(a:borderhrz)
    exec "syn match CalNormal display " string('^'.a:whiteleft.'+')
  endif
endfunction

"*****************************************************************
"* make_dir : make directory
"*----------------------------------------------------------------
"*   dir : directory
"*****************************************************************
function! s:make_dir(dir) abort
  if isdirectory(a:dir)
    return 0
  endif
  return mkdir(a:dir, 'p') ? 0 : 1
endfunction

"*****************************************************************
"* diary : calendar hook function
"*----------------------------------------------------------------
"*   day   : day you actioned
"*   month : month you actioned
"*   year  : year you actioned
"*****************************************************************
function! calendar#diary(day, month, year, week, dir) abort
  if !isdirectory(expand(g:calendar_diary))
    call confirm("please create diary directory : ".g:calendar_diary, 'OK')
    return
  endif
  let l:sfile = expand(g:calendar_diary) . "/" . printf("%04d", a:year)
  if isdirectory(l:sfile) == 0
    if s:make_dir(l:sfile) != 0
      return
    endif
  endif
  let l:sfile = l:sfile . "/" . printf("%02d", a:month)
  if isdirectory(l:sfile) == 0
    if s:make_dir(l:sfile) != 0
      return
    endif
  endif
  let l:sfile = expand(l:sfile) . "/" . printf("%02d", a:day) . g:calendar_diary_extension
  let l:sfile = substitute(l:sfile, ' ', '\\ ', 'g')
  let l:vbufnr = bufnr('__Calendar')

  exe "wincmd w"
  exe "edit  " . l:sfile
  exe "setfiletype " . g:calendar_filetype
  let l:dir = getbufvar(l:vbufnr, "CalendarDir")
  let l:vyear = getbufvar(l:vbufnr, "CalendarYear")
  let l:vmnth = getbufvar(l:vbufnr, "CalendarMonth")
  exe "auto BufDelete ".escape(l:sfile, ' \\')." call calendar#show(" . l:dir . "," . l:vyear . "," . l:vmnth . ")"
endfunction

"*****************************************************************
"* sign : calendar sign function
"*----------------------------------------------------------------
"*   day   : day of sign
"*   month : month of sign
"*   year  : year of sign
"*****************************************************************
function! calendar#sign(day, month, year) abort
  let l:sfile = g:calendar_diary."/".printf("%04d", a:year)."/".printf("%02d", a:month)."/".printf("%02d", a:day).g:calendar_diary_extension
  return filereadable(expand(l:sfile))
endfunction

"*****************************************************************
"* CalendarVar : get variable
"*----------------------------------------------------------------
"*****************************************************************
function! s:CalendarVar(var) abort
  if !exists(a:var)
    return ''
  endif
  exec 'return ' . a:var
endfunction

"*****************************************************************
"* CalendarBuildKeymap : build keymap
"*----------------------------------------------------------------
"*****************************************************************
function! s:CalendarBuildKeymap(dir, vyear, vmnth) abort
  nnoremap <silent> <buffer> <Plug>CalendarClose  :call calendar#close()<cr>
  nnoremap <silent> <buffer> <Plug>CalendarDoAction  :call calendar#action()<cr>
  nnoremap <silent> <buffer> <Plug>CalendarDoAction  :call calendar#action()<cr>
  nnoremap <silent> <buffer> <Plug>CalendarGotoToday :call calendar#show(b:CalendarDir)<cr>
  nnoremap <silent> <buffer> <Plug>CalendarShowHelp  :call <SID>CalendarHelp()<cr>
  execute 'nnoremap <silent> <buffer> <Plug>CalendarReDisplay :call calendar#show(' . a:dir . ',' . a:vyear . ',' . a:vmnth . ')<cr>'
  let l:pnav = get(split(g:calendar_navi_label, ','), 0, '')
  let l:nnav = get(split(g:calendar_navi_label, ','), 2, '')
  execute 'nnoremap <silent> <buffer> <Plug>CalendarGotoPrevMonth :call calendar#action("<' . l:pnav . '")<cr>'
  execute 'nnoremap <silent> <buffer> <Plug>CalendarGotoNextMonth :call calendar#action("' . l:nnav . '>")<cr>'
  execute 'nnoremap <silent> <buffer> <Plug>CalendarGotoPrevYear  :call calendar#action("PrevYear")<cr>'
  execute 'nnoremap <silent> <buffer> <Plug>CalendarGotoNextYear  :call calendar#action("NextYear")<cr>'

  nmap <buffer> <2-LeftMouse> <Plug>CalendarDoAction

  execute 'nmap <buffer> ' . s:calendar_keys['close'] . ' <Plug>CalendarClose'
  execute 'nmap <buffer> ' . s:calendar_keys['do_action'] . ' <Plug>CalendarDoAction'
  execute 'nmap <buffer> ' . s:calendar_keys['goto_today'] . ' <Plug>CalendarGotoToday'
  execute 'nmap <buffer> ' . s:calendar_keys['show_help'] . ' <Plug>CalendarShowHelp'
  execute 'nmap <buffer> ' . s:calendar_keys['redisplay'] . ' <Plug>CalendarRedisplay'

  execute 'nmap <buffer> ' . s:calendar_keys['goto_next_month'] . ' <Plug>CalendarGotoNextMonth'
  execute 'nmap <buffer> ' . s:calendar_keys['goto_prev_month'] . ' <Plug>CalendarGotoPrevMonth'
  execute 'nmap <buffer> ' . s:calendar_keys['goto_next_year'] . ' <Plug>CalendarGotoNextYear'
  execute 'nmap <buffer> ' . s:calendar_keys['goto_prev_year'] . ' <Plug>CalendarGotoPrevYear'
endfunction

"*****************************************************************
"* CalendarHelp : show help for Calendar
"*----------------------------------------------------------------
"*****************************************************************
function! s:CalendarHelp() abort
  let l:ck = s:calendar_keys
  let l:max_width = max(map(values(l:ck), 'len(v:val)'))
  let l:offsets = map(copy(l:ck), '1 + l:max_width - len(v:val)')

  echohl SpecialKey
  echo l:ck['goto_prev_month']  . repeat(' ', l:offsets['goto_prev_month']) . ': goto prev month'
  echo l:ck['goto_next_month']  . repeat(' ', l:offsets['goto_next_month']) . ': goto next month'
  echo l:ck['goto_prev_year']   . repeat(' ', l:offsets['goto_prev_year'])  . ': goto prev year'
  echo l:ck['goto_next_year']   . repeat(' ', l:offsets['goto_next_year'])  . ': goto next year'
  echo l:ck['goto_today']       . repeat(' ', l:offsets['goto_today'])      . ': goto today'
  echo l:ck['close']            . repeat(' ', l:offsets['close'])           . ': close window'
  echo l:ck['redisplay']        . repeat(' ', l:offsets['redisplay'])       . ': re-display window'
  echo l:ck['show_help']        . repeat(' ', l:offsets['show_help'])       . ': show this help'
  if g:calendar_action == "calendar#diary"
    echo l:ck['do_action']      . repeat(' ', l:offsets['do_action'])       . ': show diary'
  endif
  echo ''
  echohl Question

  let l:vk = [
  \ 'calendar_erafmt',
  \ 'calendar_mruler',
  \ 'calendar_wruler',
  \ 'calendar_weeknm',
  \ 'calendar_navi_label',
  \ 'calendar_diary',
  \ 'calendar_mark',
  \ 'calendar_navi',
  \]
  let l:max_width = max(map(copy(l:vk), 'len(v:val)'))

  for l:_ in l:vk
    let l:v = get(g:, l:_, '')
    echo l:_ . repeat(' ', l:max_width - len(l:_)) . ' = ' .  l:v
  endfor
  echohl MoreMsg
  echo "[Hit any key]"
  echohl None
  call getchar()
  redraw!
endfunction

function! calendar#search(keyword) abort
  if g:calendar_search_grepprg == "internal"
    exe "vimgrep /" . a:keyword."/" . escape(g:calendar_diary," ") . "/**/*" . g:calendar_diary_extension . "|cw"
  else
    silent execute g:calendar_search_grepprg . " '" . a:keyword . "' " . escape(g:calendar_diary," ") . "/**/*" . g:calendar_diary_extension
    silent execute "cw"
  endif
endfunction

hi def link CalNavi     Search
hi def link CalSaturday Statement
hi def link CalSunday   Type
hi def link CalRuler    StatusLine
hi def link CalWeeknm   Comment
hi def link CalToday    Directory
hi def link CalHeader   Special
hi def link CalMemo     Identifier
hi def link CalNormal   Normal
hi def link CalCurrList Error
