(add-to-load-path "/home/arisu/.config/guix")

(use-modules (gnu)
             (gnu packages)
             (gnu packages linux)
             (packages)
             ;(services)
             ;(filesystems)
             (nongnu packages linux)
             (nongnu packages nvidia)
             (nongnu system linux-initrd)
             (nonguix transformations))

(use-service-modules cups desktop networking ssh xorg sddm)

(define %arisu-os
  (operating-system
   (locale "en_GB.utf8")
   (timezone "Europe/Lisbon")
   (keyboard-layout (keyboard-layout "us"))
   (host-name "wired")

   (kernel-arguments '("modprobe.blacklist=nouveau"))
   (kernel linux)
   (initrd microcode-initrd)
   (firmware (list linux-firmware))

   (packages (append arisu-desktop-packages
                     arisu-development-packages
                     arisu-server-packages
                     %base-packages))

   (users (cons* (user-account
                  (name "arisu")
                  (comment "arisu")
                  (group "users")
                  (home-directory "/home/arisu")
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))
                 %base-user-accounts))

   (services
    (append
     (list (service xfce-desktop-service-type)
           (service sddm-service-type
                    (sddm-configuration
                     (remember-last-session? #f)
                     (sessions-directory "")
                     (xorg-configuration
                      (xorg-configuration
                       (keyboard-layout keyboard-layout)
                       (drivers '("nvidia"))))))
           (service openssh-service-type)
           (service cups-service-type)
           (simple-service 'load-nvidia-drm activation-service-type
                           #~(system* #$(file-append kmod "/bin/modprobe")
                                      "nvidia-drm")))
     (modify-services %desktop-services
		      (delete gdm-service-type)
		      (guix-service-type config =>
					 (guix-configuration
					  (inherit config)
					  (substitute-urls
					   (append (list "https://substitutes.nonguix.org")
						   %default-substitute-urls))
					  (authorized-keys
					   (append (list (local-file "./nonguix.pub"))
						   %default-authorized-guix-keys)))))))
   
   (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))
   
   (swap-devices (list (swap-space
                        (target (uuid
                                 "ea574626-49dd-4740-8d1d-168240f22ba4")))))

   (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "CE74-0C03"
                                       'fat32))
                         (type "vfat"))
			(file-system
                         (mount-point "/")
                         (device (uuid
                                  "e92ece76-5a72-43b1-88b8-0b0b39539b5b"
                                  'ext4))
                         (type "ext4")) %base-file-systems))))

((nonguix-transformation-nvidia
  #:driver nvda-595
  #:open-source-kernel-module? #t
  #:configure-xorg? sddm-service-type)
 %arisu-os)
