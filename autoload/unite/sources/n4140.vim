scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let g:unite#sources#n4140#cache_dir = get(g:, 'unite#sources#n4140#cache_dir', unite#get_data_directory() . '/n4140')
let g:unite#sources#n4140#pdf_path = get(g:, 'unite#sources#n4140#pdf_path', '')
let g:unite#sources#n4140#txt_path = get(g:, 'unite#sources#n4140#txt_path', '')
let g:unite#sources#n4140#is_multiline = get(g:, 'unite#sources#n4140#is_multiline', 0)

if !isdirectory(g:unite#sources#n4140#cache_dir)
    call mkdir(g:unite#sources#n4140#cache_dir, 'p')
endif

let s:source = {
    \ 'name' : 'n4140',
    \ 'description' : 'quick look into N4140, Working Draft standard nearest by ISO/IEC14882:2014',
    \ 'default_action' : {'common' : 'n4140'},
    \ 'syntax' : 'uniteSource__N4140',
    \ 'action_table' : {},
    \ 'hooks' : {},
    \ }

function! unite#sources#n4140#define()
    return s:source
endfunction

function! s:error(msg)
    return "untie-n4140: " . a:msg
endfunction

function! s:download_pdf(dir) abort
    if executable('curl')
        let cmd = 'curl -L -o %s %s 2>&1'
    elseif executable('wget')
        let cmd = 'wget -O %s %s 2>&1'
    else
        throw s:error("'curl' or 'wget' command is required to download pdf file ")
    endif

    echo 'unite-n4140: Downloading n4140.pdf to ' . a:dir . '/n4140.pdf ...'

    let result = system(printf(cmd, a:dir . '/n4140.pdf', 'https://github.com/cplusplus/draft/raw/master/papers/n4140.pdf'))
    if v:shell_error
        throw s:error("Failed to download n4140.pdf: " . result)
    endif

    echo 'Done!'
endfunction

function! s:convert_to_txt(pdf, txt) abort
    if !filereadable(a:pdf)
        throw s:error('Path to pdf file is invalid')
    endif

    if !executable('pdftotext')
        throw s:error("'pdftotext' command is not found")
    endif

    echo 'unite-n4140: Converting from pdf file to txt file...'

    let result = system(printf('pdftotext -layout -nopgbrk %s - > %s', a:pdf, a:txt))
    if v:shell_error
        throw s:error("Failed to convert " . a:pdf . " to " a:txt)
    endif

    echo 'Done!'
endfunction

function! s:get_pdf_path() abort
    if g:unite#sources#n4140#pdf_path !=# ''
        return g:unite#sources#n4140#pdf_path
    endif

    if filereadable(g:unite#sources#n4140#cache_dir . '/n4140.pdf')
        return g:unite#sources#n4140#cache_dir . '/n4140.pdf'
    endif

    call s:download_pdf(g:unite#sources#n4140#cache_dir)

    if !filereadable(g:unite#sources#n4140#cache_dir . '/n4140.pdf')
        throw s:error('Failed to get the path to n4140.pdf')
    endif

    return g:unite#sources#n4140#cache_dir . '/n4140.pdf'
endfunction

function! s:get_txt_path() abort
    if g:unite#sources#n4140#txt_path !=# ''
        return g:unite#sources#n4140#txt_path
    endif

    if filereadable(g:unite#sources#n4140#cache_dir . '/n4140.txt')
        return g:unite#sources#n4140#cache_dir . '/n4140.txt'
    endif

    let pdf_path = s:get_pdf_path()

    let txt_path = fnamemodify(pdf_path, ':r') . '.txt'
    if !filereadable(txt_path)
        call s:convert_to_txt(pdf_path, txt_path)
    endif

    return txt_path
endfunction

function! s:cache_sections(txt) abort
    let contents = readfile(a:txt)
    let sections = []

    for lnum in range(1, len(contents))
        let idx = lnum - 1

        let match = matchlist(contents[idx], '^\s*\([0-9.]\+\)\s\+\([^\[]\+\) \[[a-z.]\+]$')
        if len(match) >= 3 && match[2] !~# '^\s\+$'
            let sections += [
                \   printf("%d\t%s\t%s", lnum, match[1], substitute(match[2], '\s*$','',''))
                \ ]
        endif
    endfor

    call writefile(sections, g:unite#sources#n4140#cache_dir . '/cache')

    return sections
endfunction

function! s:get_sections() abort
    let cache_path = g:unite#sources#n4140#cache_dir . '/cache'
    if filereadable(cache_path)
        return readfile(cache_path)
    endif

    return s:cache_sections(s:get_txt_path())
endfunction

function s:jump_to_section_under_cursor()
    " Note:
    " Split 'vi(' and '"gy' because of the behavior when the cursor is outside
    " the parentheses.
    normal! vi(
    normal! "gy

    let ref = getreg('g')
    if ref !~# '[[:digit:].]\+'
        echo 'unite-n4140: No reference to section is found under the cursor.'
        return
    endif

    let sections = s:get_sections()
    for s in sections
        let [line, section, content] = split(s, "\t")
        if section == ref
            if line !=# ''
                execute str2nr(line)
                return
            endif
        endif
    endfor
endfunction

function! s:open_n4140(line) abort
    let txt = s:get_txt_path()
    let bufnr = bufnr(unite#util#escape_file_searching(txt))
    if bufnr != bufnr('%')
        execute "view! " . txt
    endif

    if !exists('b:current_syntax') || b:current_syntax !=# 'n4140'
        setl syntax=unite-source-N4140
        let b:current_syntax = 'n4140'
        setl nowrap nonumber nolist
        nnoremap K :<C-u>call <SID>jump_to_section_under_cursor()<CR>
    endif

    execute a:line
    normal! zz
    return bufnr
endfunction

function! s:highlight_candidates()
    syntax match uniteSource__N4140_Number /\d[0-9\.]*/ contained containedin=uniteSource__N4140 nextgroup=uniteSource__N4140_Separator
    syntax match uniteSource__N4140_Separator /:/ contained containedin=uniteSource__N4140
    highlight default link uniteSource__N4140_Number Type
    highlight default link uniteSource__N4140_Separator Type
endfunction

function! s:source.gather_candidates(args, context)
    try
        let sections = map(s:get_sections(), "split(v:val,'\t')")
        let txt = s:get_txt_path()
    catch 'unite-n4140:'
        call unite#print_error(v:exception)
        return []
    endtry

    return map(sections, "{
        \ 'word' : v:val[1] . repeat(' ', 12 - strlen(v:val[1])) . ': ' . v:val[2],
        \ 'is_multiline' : g:unite#sources#n4140#is_multiline,
        \ 'action__n4140_line' : v:val[0]
        \ }")
endfunction

let s:source.action_table.n4140 = {
    \ 'description' : 'jump to the section of N4140'
    \ }

function! s:source.action_table.n4140.func(candidate)
    let bufnr = s:open_n4140(a:candidate.action__n4140_line)
    call unite#remove_previewed_buffer_list(bufnr)
endfunction

let s:source.action_table.preview = {
    \ 'description' : 'preview the section',
    \ 'is_quit' : 0,
    \ }

function! s:source.action_table.preview.func(candidate)
    let preview_windows = filter(range(1, winnr('$')), 'getwinvar(v:val, "&previewwindow") != 0')

    if empty(preview_windows)
        execute 'pedit!' s:get_txt_path()
        let preview_windows = filter(range(1, winnr('$')), 'getwinvar(v:val, "&previewwindow") != 0')
    endif

    let winnr = winnr()
    execute preview_windows[0] . 'wincmd w'
    let bufnr = s:open_n4140(a:candidate.action__n4140_line)
    execute winnr . 'wincmd w'

    if !buflisted(bufnr)
        call unite#add_previewed_buffer_list(bufnr)
    endif
endfunction

function! s:source.hooks.on_syntax(args, context)
    call s:highlight_candidates()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
