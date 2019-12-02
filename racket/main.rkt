#lang racket
(require web-server/templates
         web-server/dispatch
         web-server/servlet
         web-server/servlet-env
         racket/runtime-path)
(require (for-syntax racket))
(require "billing.rkt")

(define-runtime-path static-path "../dist/")

(define (request-language req)
  (match (extract-binding/single 'accept-language
                                       (request-headers req))
    [(regexp #rx"zh-CN") "zhs"]
    [(regexp #rx"zh") "zht"]
    [_ "en"]))

(define (auto-jump req)
  (let ([lang (request-language req)])
    (response/full 302
                   #"Found"
                   (current-seconds)
                   TEXT/HTML-MIME-TYPE
                   (list (make-header #"Location"
                                      (match lang
                                        ["zhs" #"/zhs"]
                                        ["zht" #"/zht"]
                                        [_ #"/en"]))
                         (make-header #"Vary" #"Accept-Language"))
                   '())))

(define exit-global (exit-handler))

(define-values (page-dispatch url)
  (dispatch-rules
   [("") auto-jump]
   [("billing" "userinfo") serve-userinfo]
   [("billing" "alipay") serve-alipay]))

(displayln static-path)

(serve/servlet page-dispatch
               #:port 9000
               #:launch-browser? #f
               #:servlet-regexp #rx""
               #:extra-files-paths (list 
                                    static-path))