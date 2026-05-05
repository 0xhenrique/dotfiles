(use-modules (gnu)
             (gnu packages)
             (gnu packages linux)
             (nongnu packages linux)
             (nongnu packages nvidia)
             (nongnu system linux-initrd)
             (nonguix transformations))

(define arisu-desktop-packages
  (list (specification->package "emacs")
        (specification->package "flameshot")
        (specification->package "mpv")
        (specification->package "rhythmbox")))

(define arisu-development-packages
  (list (specification->package "git")
        (specification->package "gimp")
        (specification->package "postgresql")
        (specification->package "ripgrep")
        (specification->package "fd")
        (specification->package "nss-certs")))

(define arisu-server-packages
  (list (specification->package "btop")
        (specification->package "deluge")
        (specification->package "nicotine+")))

(use-service-modules cups desktop networking ssh xorg sddm samba)

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
                                      "nvidia-drm"))
           (service samba-service-type
                    (samba-configuration
                     (enable-smbd? #t)
                     (config-file
                      (plain-file "smb.conf" "
[global]
map to guest = Bad User
logging = syslog@1
server string = hack me
workgroup = WORKGROUP
socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072

[hdd1]
comment = Primary Drive
browsable = yes
path = /public/hdd1
read only = no
guest ok = yes
guest only = yes
create mask = 0644
directory mask = 0755

[hdd2]
comment = Secondary Drive
browsable = yes
path = /public/hdd2
read only = no
guest ok = yes
guest only = yes
create mask = 0644
directory mask = 0755
")))))
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
                         (device (uuid "CE74-0C03" 'fat32))
                         (type "vfat"))
                        (file-system
                         (mount-point "/")
                         (device (uuid "e92ece76-5a72-43b1-88b8-0b0b39539b5b" 'ext4))
                         (type "ext4"))
                        ;; sirius - primary storage (NTFS, NVMe)
                        (file-system
                         (mount-point "/public/hdd1")
                         (device (file-system-label "Sirius"))
                         (type "ntfs-3g")
                         (flags '(no-atime))
                         (needed-for-boot? #f)
                         (skip-check-if-clean? #t)
                         (create-mount-point? #t))
                        ;; rigel - secondary storage (ext4, HDD)
                        (file-system
                         (mount-point "/public/hdd2")
                         (device (uuid "bf91bd86-c9ea-4675-95a8-cc172afdec29" 'ext4))
                         (type "ext4")
                         (flags '(no-atime))
                         (needed-for-boot? #f)
                         (skip-check-if-clean? #t)
                         (create-mount-point? #t))
                        %base-file-systems))))

((nonguix-transformation-nvidia
  #:driver nvda-595
  #:open-source-kernel-module? #t
  #:configure-xorg? sddm-service-type)
 %arisu-os)
