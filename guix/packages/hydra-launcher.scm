(define-module (packages hydra-launcher)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix build-system copy)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg)
  #:export (hydra-launcher))

(define-public hydra-launcher
  (package
    (name "hydra-launcher")
    (version "3.9.5")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/hydralauncher/hydra/releases/download/v"
                           version "/hydralauncher-" version ".AppImage"))
       (sha256
        (base32 "045cpjj3pbq195ynixxlvdfsrh24mz8p661nxcx0sal6wy9pjl8l"))))
    (build-system copy-build-system)
    (supported-systems '("x86_64-linux"))
    (arguments
     (list
      #:install-plan
      #~'(("squashfs-root/" "lib/hydra-launcher/"))
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (copy-file source "hydralauncher.AppImage")
              (invoke "sh" "-c"
                      "offset=$(grep -abo hsqs hydralauncher.AppImage | head -1 | cut -d: -f1) && \
                       dd if=hydralauncher.AppImage of=squashfs.img bs=1 skip=$offset 2>/dev/null && \
                       unsquashfs -f -d squashfs-root squashfs.img")))
          (add-after 'install 'create-wrapper
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (binary (string-append out "/lib/hydra-launcher/hydralauncher"))
                     (bash (search-input-file inputs "/bin/bash"))
                     (lib-dirs
                      (filter identity
                       (map (lambda (pkg)
                              (let ((path (assoc-ref inputs pkg)))
                                (and path (string-append path "/lib"))))
                            '("alsa-lib" "at-spi2-core" "cairo" "cups"
                              "dbus" "eudev" "expat" "gcc:lib" "glib"
                              "gtk+" "libdrm" "libx11" "libxcb"
                              "libxcomposite" "libxdamage" "libxext"
                              "libxfixes" "libxkbcommon" "libxrandr"
                              "mesa" "nspr" "nss" "pango" "pulseaudio"))))
                     (ld-path
                      (string-join
                       (append lib-dirs
                               (list (string-append
                                      (assoc-ref inputs "nss") "/lib/nss")))
                       ":"))
                     (fontconfig-path
                      (or (assoc-ref inputs "fontconfig")
                          (assoc-ref inputs "fontconfig-minimal"))))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/hydralauncher")
                  (lambda (port)
                    (format port "#!~a~%" bash)
                    (format port "export LD_LIBRARY_PATH=\"~a${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"~%"
                            ld-path)
                    (when fontconfig-path
                      (format port "export FONTCONFIG_PATH=\"~a/etc/fonts\"~%"
                              fontconfig-path))
                    (format port "export ELECTRON_OZONE_PLATFORM_HINT=auto~%")
                    (format port "exec ~a \"$@\"~%" binary)))
                (chmod (string-append bin "/hydralauncher") #o755)))))))
    (native-inputs (list patchelf squashfs-tools))
    (inputs
     (list alsa-lib
           at-spi2-core
           bash-minimal
           cairo
           cups
           dbus
           eudev
           expat
           fontconfig
           `(,gcc "lib")
           glib
           gtk+
           libdrm
           libx11
           libxcb
           libxcomposite
           libxdamage
           libxext
           libxfixes
           libxkbcommon
           libxrandr
           mesa
           nspr
           nss
           pango
           pulseaudio))
    (home-page "https://github.com/hydralauncher/hydra")
    (synopsis "Game launcher with embedded BitTorrent client")
    (description "Hydra is a game launcher with its own embedded BitTorrent
client and a self-managed repack manifest.  It supports downloading and
installing games from various sources.")
    (license license:expat)))

hydra-launcher
