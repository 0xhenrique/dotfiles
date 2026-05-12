;; This is a sample Guix Home configuration which can help setup your
;; home directory in the same declarative manner as Guix System.
;; For more information, see the Home Configuration section of the manual.
(define-module (guix-home-config)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu system shadow))

(define home-config
  (home-environment
    (packages
      (list (specification->package "emacs")
            (specification->package "mpv")
			(specification->package "librewolf")
			(specification->package "neofetch")
			(specification->package "icecat")
			(specification->package "btop")
			(specification->package "node")
			(specification->package "steam")
			(specification->package "patchelf")
			(specification->package "file")
			(specification->package "font-gnu-unifont")
			(specification->package "setxkbmap")
            (specification->package "rhythmbox")
            (specification->package "git")
            (specification->package "gimp")
            (specification->package "ripgrep")
            (specification->package "fd")
            (specification->package "deluge")
            (specification->package "nicotine+")
            (specification->package "musescore")
            (specification->package "font-bravura")
            (specification->package "pulseaudio")))
    (services
      (append
        (list
          ;; Uncomment the shell you wish to use for your user:
          ;(service home-bash-service-type)
          ;(service home-fish-service-type)
          ;(service home-zsh-service-type)

          (service home-files-service-type
           `((".guile" ,%default-dotguile)
             (".Xdefaults" ,%default-xdefaults)))

          (service home-xdg-configuration-files-service-type
           `(("gdb/gdbinit" ,%default-gdbinit)
             ("nano/nanorc" ,%default-nanorc))))

        %base-home-services))))

home-config
