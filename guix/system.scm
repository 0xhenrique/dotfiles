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
             (packages)
             (services)
             (filesystems)
             (nongnu packages linux))

(use-service-modules desktop networking ssh xorg)

(operating-system
  (locale "en_GB.utf8")
  (timezone "Europe/Lisbon")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "wired")
  
  ;; Non-free kernel for hardware compatibility
  (kernel linux)
  (firmware (list linux-firmware))

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
  (services (append (list
                     ;; Server services
                     arisu-samba-service
                     arisu-postgresql-service

                     ;; System services
                     (service openssh-service-type)
                     
                     ;; X11 configuration for EXWM
                     (set-xorg-configuration
                      (xorg-configuration 
                       (keyboard-layout keyboard-layout))))

                    ;; Base desktop services (networking, power management, etc.)
                    %desktop-services))

  ;; Boot configuration
  (bootloader (bootloader-configuration
               (bootloader grub-efi-bootloader)
               (targets (list "/boot/efi"))
               (keyboard-layout keyboard-layout)))

  ;; Swap space
  (swap-devices (list (swap-space
                       (target (uuid "b47f38e0-3f1f-43be-b255-e708127ceccd")))))

  ;; File systems
  (file-systems arisu-file-systems))
