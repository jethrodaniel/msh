" Vim syntax file
" Language:  peg
" Version:   0.2.0

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn keyword pegTodo        contained TODO FIXME HACK NOTE

syn region  pegComment     display oneline start='#' end='$'
                            \ contains=pegTodo,@Spell

syn region  pegClass       transparent matchgroup=pegKeyword
                            \ start='\<class\>' end='\<rule\>'he=e-4
                            \ contains=pegComment,pegPrecedence,
                            \ pegTokenDecl,pegExpect,pegOptions,pegConvert,
                            \ pegStart,

syn keyword pegTokenDecl   contained token
                            \ nextgroup=pegTokenR skipwhite skipnl

syn match   pegTokenR      contained '\<\u[A-Z0-9_]*\>'
                            \ nextgroup=pegTokenR skipwhite skipnl

syn keyword pegExpect      contained expect
                            \ nextgroup=pegNumber skipwhite skipnl

syn match   pegNumber      contained '\<\d\+\>'

syn keyword pegOptions     contained options
                            \ nextgroup=pegOptionsR skipwhite skipnl

syn keyword pegOptionsR    contained omit_action_call result_var
                            \ nextgroup=pegOptionsR skipwhite skipnl

syn region  pegConvert     transparent contained matchgroup=pegKeyword
                            \ start='\<convert\>' end='\<end\>'
                            \ contains=pegComment,pegConvToken skipwhite
                            \ skipnl

syn match   pegConvToken   contained '\<\u[A-Z0-9_]*\>'
                            \ nextgroup=pegString skipwhite skipnl

syn keyword pegStart       contained start
                            \ nextgroup=pegTargetS skipwhite skipnl

syn match   pegTargetS     contained '\<\l[a-z0-9_]*\>'

syn match   pegSpecial     contained '\\["'\\]'

syn region  pegString      start=+"+ skip=+\\\\\|\\"+ end=+"+
                            \ contains=pegSpecial
syn region  pegString      start=+'+ skip=+\\\\\|\\'+ end=+'+
                            \ contains=pegSpecial

syn region  pegRules       transparent matchgroup=pegKeyword start='\<rule\>'
                            \ end='\<end\>' contains=pegComment,pegString,
                            \ pegNumber,pegToken,pegTarget,pegDelimiter,
                            \ pegAction

syn match   pegTarget      contained '\<\l[a-z0-9_]*\>'

syn match   pegDelimiter   contained '[:|]'

syn match   pegToken       contained '\<\u[A-Z0-9_]*\>'

syn include @pegRuby       syntax/ruby.vim

syn region  pegAction      transparent matchgroup=pegDelimiter
                            \ start='{' end='}' contains=@pegRuby

syn region  pegHeader      transparent matchgroup=pegPreProc
                            \ start='^---- header.*' end='^----'he=e-4
                            \ contains=@pegRuby

syn region  pegInner       transparent matchgroup=pegPreProc
                            \ start='^---- inner.*' end='^----'he=e-4
                            \ contains=@pegRuby

syn region  pegFooter      transparent matchgroup=pegPreProc
                            \ start='^---- footer.*' end='^----'he=e-4
                            \ contains=@pegRuby

syn sync match pegSyncHeader  grouphere pegHeader '^---- header'
syn sync match pegSyncInner   grouphere pegInner  '^---- inner'
syn sync match pegSyncFooter  grouphere pegFooter '^---- footer'

hi def link pegTodo        Todo
hi def link pegComment     Comment
hi def link pegTokenDecl   Keyword
hi def link pegToken       Identifier
hi def link pegTokenR      pegToken
hi def link pegExpect      Keyword
hi def link pegNumber      Number
hi def link pegOptions     Keyword
hi def link pegOptionsR    Identifier
hi def link pegConvToken   pegToken
hi def link pegStart       Keyword
hi def link pegTargetS     Type
hi def link pegSpecial     special
hi def link pegString      String
hi def link pegTarget      Type
hi def link pegDelimiter   Delimiter
hi def link pegKeyword     Keyword

let b:current_syntax = "peg"

let &cpo = s:cpo_save
unlet s:cpo_save
