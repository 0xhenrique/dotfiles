 ;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.


;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (gnu)
             (gnu packages)
             (gnu services samba)
             (nongnu packages linux))

(use-service-modules cups desktop networking ssh xorg)

(operating-system
  (locale "en_GB.utf8")
  (timezone "Europe/Lisbon")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "home")

  ;; Non-free kernel because of my fucking graphics card
  (kernel linux)
  (firmware (list linux-firmware))

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "arisu")
                  (comment "arisu")
                  (group "users")
                  (home-directory "/home/arisu")
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (list
					 (specification->package "nss-certs")
					 (specification->package "emacs")
					 (specification->package "emacs-desktop-environment")
					 (specification->package "emacs-exwm"))
                    %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (append (list (service xfce-desktop-service-type)
                 (service openssh-service-type)
                 (service cups-service-type)
                 (set-xorg-configuration
                  (xorg-configuration (keyboard-layout keyboard-layout)))
                 (service samba-service-type 
                          (samba-configuration
                           (enable-smbd? #t)
                           (config-file 
                            (plain-file "smb.conf" "
[global]
# Security settings
map to guest = Bad User
logging = syslog@1
server string = hack me
workgroup = WORKGROUP

# Performance
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

           ;; This is the default list of services we
           ;; are appending to.
           %desktop-services))
  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                        (target (uuid
                                 "e7127ac8-58b4-42a3-9aa8-2f4efed0bec0")))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "418C-8A00"
                                       'fat32))
                         (type "vfat"))
                       
                       (file-system
                         (mount-point "/")
                         (device (uuid
                                  "9b2a0c03-8a39-49a9-8fc1-94d9a692c4cf"
                                  'ext4))
                         (type "ext4"))

                       (file-system
                        (mount-point "/public/hdd1") 
                        (device (uuid "bf91bd86-c9ea-4675-95a8-cc172afdec29" 'ext4))
                        (type "ext4")
                        (flags '(no-atime))
                        (needed-for-boot? #f)
                        (skip-check-if-clean? #t)
                        (create-mount-point? #t))
                       %base-file-systems)))
