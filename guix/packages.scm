(define-module (packages)
  #:use-module (guix)
  #:use-module (guix packages)
  #:use-module (guix profiles)
  #:use-module (gnu packages)
  #:export (arisu-desktop-packages
            arisu-development-packages
            arisu-server-packages))

;;; Desktop environment packages
(define arisu-desktop-packages
  (list (specification->package "emacs")
        (specification->package "emacs-exwm")
        (specification->package "emacs-desktop-environment")
        (specification->package "kitty")
        (specification->package "flameshot")
        (specification->package "mpv")
        (specification->package "rhythmbox")))

;;; Development tools
(define arisu-development-packages  
  (list
        (specification->package "git")
        (specification->package "gimp")
        (specification->package "postgresql")
        (specification->package "ripgrep")
        (specification->package "fd")
        (specification->package "nss-certs")))

;;; Server and system tools
(define arisu-server-packages
  (list (specification->package "btop")
        (specification->package "deluge")
        (specification->package "nicotine+")))
