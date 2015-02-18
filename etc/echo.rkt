;;; Quick & dirty tool to check whether a HTTP(S) server is reachable in
;;; a flashlight server or old-style lantern fallback.
;;;
;;; To use, download and install racket from racket-lang.org and run
;;;
;;;     racket echo.rkt
;;;
;;; This will listen for plain HTTP connections in port 62000 (so it will be
;;; hit on port 80 in a standard flashlight/fallback setup).  It will log
;;; the full text of the incoming request to a `./plain.log` file and it will
;;; respond to the requester with a 200 OK with the same text as the body.
;;;
;;; If you run
;;;
;;;    racket echo.rkt ssl
;;;
;;; This will listen for HTTPS connections in port 62443 (mapped to 443 in
;;; a flashlight/fallback server), log the requests to `./ssl.log`, and
;;; otherwise work the same as above.
;;;
;;; A TLS public key / cert pair in PEM format is expected to be in the
;;; current directory with the names 'pk.pem' and 'cert.pem', respectively.
#lang racket

(require openssl)


(define use-ssl 
  (if (vector-member "ssl" (current-command-line-arguments)) #t #f))
(define port (if use-ssl 62443 62000))
(define log (open-output-file (if use-ssl "ssl.log" "plain.log")
                              #:exists 'replace))

(define (display-response body out)
  (display "HTTP/1.0 200 OK\r\n" out)
  (display "Server: k\r\nContent-type: text/html\r\n\r\n" out)
  (display "<html><body>" out)
  (display "<h2>" out)
  (display (if use-ssl "SSL/TLS" "Plain HTTP") out)
  (display " request:</h2>\n" out)
  (display "<pre>\n" out)
  (display body out)
  (display "</pre></body></html>\n\n" out))

(define (handle-request in out)
  (let loop ((body ""))
    (let ((line (read-line in)))
      (if (equal? line "\r")
        (begin
          (display-response body log)
          (flush-output log)
          (display-response body out))
        (loop (string-append body line "\n"))))))

(define listener (tcp-listen port 200000))

(define server-context (ssl-make-server-context 'sslv2-or-v3))

(ssl-load-private-key! server-context "pk.pem")
(ssl-load-certificate-chain! server-context "cert.pem")
(define (wrap-if-using-ssl in out)
  (if use-ssl
    (ports->ssl-ports in
                      out
                      #:mode 'accept
                      #:context server-context
                      #:close-original? #t
                      #:shutdown-on-close? #t)
    (values in out)))

(display "Listening...")
(newline)

(let loop ()
  (with-handlers
    ((exn:fail? (λ (exn) (displayln exn))))
    (let*-values (((in-tcp out-tcp) (tcp-accept/enable-break listener))
                  ((in out) (wrap-if-using-ssl in-tcp out-tcp)))
                 (thread
                   (λ ()
                      (handle-request in out)
                      (close-input-port in)
                      (close-output-port out)))))
  (loop))

(tcp-close listener)