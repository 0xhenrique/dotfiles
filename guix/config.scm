;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   ____   _   _   ___  __  __ ;;
;;  / ___| | | | | |_ _| \ \/ / ;;
;; | |  _  | | | |  | |   \  /  ;;
;; | |_| | | |_| |  | |   /  \  ;;
;;  \____|  \___/  |___| /_/\_\ ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-load-path "/home/arisu/.config/guix")

(use-modules (gnu)
             (gnu packages)
             (gnu services sddm)
             (packages)
             (services)
             (filesystems)
             (nongnu packages linux)
             (nongnu packages nvidia)
             (nongnu system linux-initrd)
             (nonguix transformations))

(use-service-modules desktop networking ssh xorg)

(define %arisu-os
  (operating-system
    (locale "en_GB.utf8")
    (timezone "Europe/Lisbon")
    (keyboard-layout (keyboard-layout "us"))
    (host-name "wired")

    ;; Blacklist nouveau to avoid conflicts with nvidia driver
    (kernel-arguments '("modprobe.blacklist=nouveau"))

    ;; Non-free kernel - pinned for stability with NVIDIA drivers
    (kernel linux-6.18)
    (initrd microcode-initrd)
    (firmware (cons* linux-firmware %base-firmware))

    ;; User accounts
    (users (cons* (user-account
                   (name "arisu")
                   (comment "arisu")
                   (group "users")
                   (home-directory "/home/arisu")
                   (supplementary-groups '("wheel" "netdev" "audio" "video")))
                  %base-user-accounts))

    ;; System packages
    (packages (append arisu-desktop-packages
                      arisu-development-packages
                      arisu-server-packages
                      %base-packages))

    ;; Services
    (services (cons*
               ;; SDDM display manager (GDM has known issues with NVIDIA)
               (service sddm-service-type)

               ;; Server services
               arisu-samba-service
               arisu-postgresql-service

               ;; System services
               (service openssh-service-type)

               ;; Base desktop services without GDM
               (modify-services %desktop-services
                 (delete gdm-service-type))))

    ;; Boot configuration
    (bootloader (bootloader-configuration
                 (bootloader grub-efi-bootloader)
                 (targets (list "/boot/efi"))
                 (keyboard-layout keyboard-layout)))

    ;; Swap space
    (swap-devices (list (swap-space
                         (target (uuid "b47f38e0-3f1f-43be-b255-e708127ceccd")))))

    ;; File systems
    (file-systems arisu-file-systems)))

;; Apply NVIDIA transformation - handles driver, kernel modules, and Xorg setup
((nonguix-transformation-nvidia
  #:driver nvda-beta
  #:configure-xorg? sddm-service-type)
 %arisu-os)
