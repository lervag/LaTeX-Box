" Folding support for LaTeX
"
" Options
" g:LatexBox_Folding       - Turn on/off folding
" g:LatexBox_fold_parts    - Define which sections and parts to fold
" g:LatexBox_fold_envs     - Turn on/off folding of environments
" g:LatexBox_fold_preamble - Turn on/off folding of preamble
"

" {{{1 Set options
if exists('g:LatexBox_Folding')
    setl foldmethod=expr
    setl foldexpr=LatexBox_FoldLevel(v:lnum)
    setl foldtext=LatexBox_FoldText()
endif
if !exists('g:LatexBox_fold_preamble')
    let g:LatexBox_fold_preamble=1
endif
if !exists('g:LatexBox_fold_envs')
    let g:LatexBox_fold_envs=1
endif
if !exists('g:LatexBox_fold_parts')
    let g:LatexBox_fold_parts=[
                \ "part",
                \ "chapter",
                \ "section",
                \ "subsection",
                \ "subsubsection"
                \ ]
endif

" {{{1 LatexBox_FoldLevel
function! LatexBox_FoldLevel(lnum)
    let line  = getline(a:lnum)

    " Fold preamble
    if exists('g:LatexBox_fold_preamble')
        if line =~ '\s*\\documentclass'
            return ">1"
        endif
        if line =~ '\s*\\begin{document}'
            return "<1"
        endif
    endif

    " Never fold \end{document}
    if getline(a:lnum + 1) =~ '\s*\\end{document}'
        return "<1"
    endif

    " Fake sections
    if line  =~ '^\s*% Fakesection'
        return ">1"
    endif

    " Fold parts and sections
    let level = 1
    for part in g:LatexBox_fold_parts
        if line  =~ '^\s*\\' . part . '\*\?{'
            return ">" . level
        endif
        let level += 1
    endfor

    " Fold environments
    if exists('g:LatexBox_fold_envs')
        if line =~ '\\begin{.*}'
            return "a1"
        endif
        if line =~ '\\end{.*}'
            return "s1"
        endif
    endif

    return "="
endfunction

" {{{1 LatexBox_FoldText help functions
function! s:LabelEnv()
    let i = v:foldend
    while i >= v:foldstart
        if getline(i) =~ '^\s*\\label'
            return matchstr(getline(i), '^\s*\\label{\zs.*\ze}')
        end
        let i -= 1
    endwhile
    return ""
endfunction

function! s:CaptionEnv()
    let i = v:foldend
    while i >= v:foldstart
        if getline(i) =~ '^\s*\\caption'
            return matchstr(getline(i), '^\s*\\caption\(\[.*\]\)\?{\zs.\+')
        end
        let i -= 1
    endwhile
    return ""
endfunction

function! s:CaptionTable()
    let i = v:foldstart
    while i <= v:foldend
        if getline(i) =~ '^\s*\\caption'
            return matchstr(getline(i), '^\s*\\caption\(\[.*\]\)\?{\zs.\+')
        end
        let i += 1
    endwhile
    return ""
endfunction

function! s:CaptionFrame(line)
    " Test simple variant first
    let caption = matchstr(a:line,'\\begin\*\?{.*}{\zs.\+')

    if ! caption == ''
        return caption
    else
        let i = v:foldstart
        while i <= v:foldend
            if getline(i) =~ '^\s*\\frametitle'
                return matchstr(getline(i),
                            \ '^\s*\\frametitle\(\[.*\]\)\?{\zs.\+')
            end
            let i += 1
        endwhile

        return ""
    endif
endfunction

" {{{1 LatexBox_FoldText
function! LatexBox_FoldText()
    " Initialize
    let line = getline(v:foldstart)
    let nlines = v:foldend - v:foldstart + 1
    let level = ''
    let title = 'Not defined'

    " Fold level
    let level = strpart(repeat('-', v:foldlevel-1) . '*',0,3)
    if v:foldlevel > 3
        let level = strpart(level, 1) . v:foldlevel
    endif
    let level = printf('%-3s', level)

    " Preamble
    if line =~ '\s*\\documentclass'
        let title = "Preamble"
    endif

    " Parts, sections and fake sections
    if line =~ '\\\(\(sub\)*section\|part\|chapter\)'
        let title =  matchstr(line,
                    \ '^\s*\\\(\(sub\)*section\|part\|chapter\)\*\?{\zs.*\ze}')
    elseif line =~ 'Fakesection:'
        let title = matchstr(line, 'Fakesection:\s*\zs.*')
    elseif line =~ 'Fakesection'
        let title = "Fakesection"
        return title
    endif

    " Environments
    if line =~ '\\begin'
        let env = matchstr(line,'\\begin\*\?{\zs\w*\*\?\ze}')
        if env == 'frame'
            let label = ''
            let caption = s:CaptionFrame(line)
        elseif env == 'table'
            let label = s:LabelEnv()
            let caption = s:CaptionTable()
        else
            let label = s:LabelEnv()
            let caption = s:CaptionEnv()
        endif
        if caption . label == ''
            let title = env
        elseif label == ''
            let title = printf('%-12s%s', env . ':',
                        \ substitute(caption, '}\s*$', '',''))
        elseif caption == ''
            let title = printf('%-12s%57s', env, '(' . label . ')')
        else
            let title = printf('%-12s%-35s %-21s', env . ':',
                        \ strpart(substitute(caption, '}\s*$', '',''),0,35),
                        \ '(' . label . ')')
        endif
    endif

    let title = strpart(title, 0, 69)
    return printf('%-3s %-69s #%5d', level, title, nlines)
endfunction

" {{{1 Footer
" vim:fdm=marker:ff=unix:ts=4:sw=4
