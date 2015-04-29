if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

syntax match uniteN4140SectionTitle     /^\s\+[0-9.]\+\s\+[^\[]\+\[[a-z.]\+]$/
syntax region uniteN4140Example         start='\[ Example:' end='end[ \n]\s*example \]' contains=uniteN4140ExampleNotice,uniteN4140Footer,uniteN4140Header
syntax region uniteN4140Note            start='\[ Note:' end='end[ \n]\s*note \]' contains=uniteN4140NoteNotice,uniteN4140Footer,uniteN4140Header
syntax match uniteN4140ExampleNotice    /Example:/ contained
syntax match uniteN4140NoteNotice       /Note:/ contained
syntax match uniteN4140Item             /—/

if has('conceal')
    syntax match uniteN4140Footer           /^\s*§\s[0-9\.]\+\s\+\d\+$/ conceal
    syntax match uniteN4140Header           /^\s*c ISO\/IEC\s\+N4140$/ conceal
else
    syntax match uniteN4140Footer           /^\s*§\s[0-9\.]\+\s\+\d\+$/
    syntax match uniteN4140Header           /^\s*c ISO\/IEC\s\+N4140$/
endif

highlight default link uniteN4140SectionTitle  Title
highlight default link uniteN4140Example       Comment
highlight default link uniteN4140Note          Comment
highlight default link uniteN4140ExampleNotice TabLine
highlight default link uniteN4140NoteNotice    TabLine
highlight default link uniteN4140Item          Question
highlight default link uniteN4140Footer        Ignore
highlight default link uniteN4140Header        Ignore


let b:current_syntax = 'unite-source-N4140'
