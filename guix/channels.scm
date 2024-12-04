;; This is an operating system configuration generated
;; by the graphical installer.
;;
;; Once installation is complete, you can learn and modify
;; this file to tweak the system configuration, and pass it
;; to the 'guix system reconfigure' command to effect your
;; changes.


;; Indicate which modules to import to access the variables
;; used in this configuration.
(use-modules (nongnu packages linux)
	     (nongnu system linux-initrd)
	     (gnu)
	     (gnu services)
	     (gnu services desktop)
	     (gnu packages))
(use-service-modules cups desktop networking ssh xorg)

(operating-system
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware))

  (locale "en_GB.utf8")
  (timezone "Europe/Lisbon")
  (keyboard-layout (keyboard-layout "us"))
  (host-name "computer")

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                  (name "void")
                  (comment "void")
                  (group "users")
                  (home-directory "/home/void")
                  (supplementary-groups '("wheel" "netdev" "audio" "video")))
                %base-user-accounts))

  ;; Packages installed system-wide.  Users can also install packages
  ;; under their own account: use 'guix search KEYWORD' to search
  ;; for packages and 'guix install PACKAGE' to install a package.
  (packages (append (list (specification->package "emacs")
                          (specification->package "emacs-exwm")
                          (specification->package "xfce")
                          (specification->package "i3-wm")
                          (specification->package "windowmaker")
                          (specification->package "fvwm")
                          (specification->package
                           "emacs-desktop-environment")
                          (specification->package "nss-certs"))
                    %base-packages))

  ;; Below is the list of system services.  To search for available
  ;; services, run 'guix system search KEYWORD' in a terminal.
  (services
   (modify-services
    (append
     (list (service gnome-desktop-service-type)
	   (service cups-service-type)
	   (service bluetooth-service-type
		    (bluetooth-configuration
		     (auto-enable? #t)))
	   (set-xorg-configuration
	    (xorg-configuration (keyboard-layout keyboard-layout))))
     %desktop-services)
    (guix-service-type config =>
		       (guix-configuration
			(inherit config)
			(substitute-urls
			 (append (list "https://substitutes.nonguix.org")
				 %default-substitute-urls))
			(authorized-keys
			 (append (list (local-file "./signing-key.pub"))
				 %default-authorized-guix-keys))))))

  (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets (list "/boot/efi"))
                (keyboard-layout keyboard-layout)))
  (swap-devices (list (swap-space
                        (target (uuid
                                 "967b378a-6003-4c89-a807-b6ea081290d9")))))

  ;; The list of file systems that get "mounted".  The unique
  ;; file system identifiers there ("UUIDs") can be obtained
  ;; by running 'blkid' in a terminal.
  (file-systems (cons* (file-system
                         (mount-point "/boot/efi")
                         (device (uuid "EFE7-BC37"
                                       'fat32))
                         (type "vfat"))
                       (file-system
                         (mount-point "/")
                         (device (uuid
                                  "56a62f6b-a353-4a15-bc08-19a73e7e10d4"
                                  'ext4))
                         (type "ext4")) %base-file-systems)))
