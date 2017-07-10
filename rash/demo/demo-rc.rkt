#lang racket/base

(provide
 (all-defined-out)
 (all-from-out rash/demo/define-rash-alias)
 (all-from-out rash/demo/more-pipeline-operators)
 (all-from-out racket/string)
 (all-from-out racket/port)
 (all-from-out racket/function)
 (all-from-out file/glob)
 (for-syntax
  (all-from-out racket/base)
  (all-from-out racket/syntax)
  (all-from-out syntax/parse)
  ))

#|
This is a demo file that could be required by `rashrc` or `rashrc.rkt`.

To use it, put the following in `~/.config/rash/rashrc`:

(require rash/demo/demo-rc.rkt)
(default-pipeline-starter! \|)

|#

(require
 rash
 rash/demo/define-rash-alias
 rash/demo/more-pipeline-operators
 racket/string
 racket/port
 racket/function
 file/glob
 (for-syntax
  racket/base
  racket/syntax
  syntax/parse
  ))

(define-syntax #%upper-triangles (make-rename-transformer #'rash))
(define-syntax #%lower-triangles (make-rename-transformer #'rash/wired))

(define-syntax =o= (make-rename-transformer #'=object-pipe=))
(define-syntax =ol= (make-rename-transformer #'=object-pipe/left=))
(define-syntax =oe= (make-rename-transformer #'=object-pipe/expression=))
(define-syntax =u= (make-rename-transformer #'=quoting-basic-unix-pipe=))
(define-syntax \|> (make-rename-transformer #'=object-pipe=))
(define-syntax \|o (make-rename-transformer #'=object-pipe=))
(define-syntax \|e (make-rename-transformer #'=object-pipe/expression=))
(define-syntax \|seq (make-rename-transformer #'=for/list=))
(define-syntax \|>l (make-rename-transformer #'=object-pipe/left=))
(define-syntax \|u (make-rename-transformer #'=quoting-basic-unix-pipe=))
(define-syntax \|g (make-rename-transformer #'=globbing-basic-unix-pipe=))
(define-syntax \| (make-rename-transformer #'=aliasing-unix-pipe=))
(define-syntax \|ou (make-rename-transformer #'=obj-if-def/unix-if-undef=))
(define-syntax _ (make-rename-transformer #'current-pipeline-argument))
;; be sure to put something like this in your rashrc
;(default-pipeline-starter! \|)


(define (highlighting-output-port outer-oport)
    (define-values (from-pipe to-pipe) (make-pipe))
    (thread (λ ()
              (define (loop)
                (let ([oline (read-line from-pipe)])
                  (if (equal? eof oline)
                      (void)
                      (begin
                        (fprintf outer-oport "\033[31m~a\033[0m~n" oline)
                        (loop)))))
              (loop)))
    to-pipe)
(define (pass-through-port outer-oport)
    (define-values (from-pipe to-pipe) (make-pipe))
    (thread (λ () (copy-port from-pipe outer-oport)))
    to-pipe)

(define real-stderr (current-error-port))
(current-error-port (highlighting-output-port (current-output-port)))


(define (grep-func str regex)
  (let ([r (cond [(regexp? regex) regex]
                 [(string? regex) regex]
                 [else (format "~a" regex)])])
    (string-append
     (string-join (filter identity
                          (for/list ([line (string-split str "\n")])
                            (and (regexp-match r line) line)))
                  "\n")
     "\n")))

(require racket/system)
(define-line-macro a
  (λ (stx)
    (syntax-case stx ()
      [(_ arg1 arg2 arg ...)
       #'(system* (find-executable-path (getenv "EDITOR")) 'arg1 'arg2 'arg ...)]
      [(_ arg)
       #'(let ([pstr (format "~a" 'arg)])
           (if (directory-exists? pstr)
               (current-directory pstr)
               (system* (find-executable-path (getenv "EDITOR")) pstr)))])))


(define-simple-rash-alias d 'ls '--color=auto)
(define-simple-rash-alias di 'ls '-l '--color=auto)
(define-simple-rash-alias gc "git" 'commit )
(define-simple-rash-alias gs "git" 'status )
(define-simple-rash-alias gd "git" 'diff )
(define-simple-rash-alias gka "gitk" '--all )
(define-simple-rash-alias gta "tig" '--all )
(define-simple-rash-alias greb "git" 'rebase )
(define-simple-rash-alias gru "git" 'remote 'update )
(define-simple-rash-alias gunadd "git" 'reset 'HEAD )
(define-simple-rash-alias gco "git" 'checkout )
(define-simple-rash-alias gcob "git" 'checkout '-b )
(define-simple-rash-alias gclone "git" 'clone '--recursive )
(define-simple-rash-alias gp "git" 'push )
(define-simple-rash-alias ga "git" 'add )

(define-rash-alias my-grep
  (syntax-parser
   [(_ pat) #'(=object-pipe= grep-func current-pipeline-argument pat)]))

;; note that grep returns 1 when it finds nothing, which is normally considered an error
(define-simple-rash-alias grep "grep" #:success (list 1))