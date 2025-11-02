(define-module (filesystems)
  #:use-module (gnu)
  #:export (arisu-file-systems))

;;; File system configuration
;; UUIDs obtained via 'blkid' command
(define arisu-file-systems
  (cons* 
   ;; EFI boot partition
   (file-system
    (mount-point "/boot/efi")
    (device (uuid "418C-8A00" 'fat32))
    (type "vfat"))
   
   ;; Root filesystem
   (file-system
    (mount-point "/")
    (device (uuid "08f6193a-049b-4676-84fb-ffb6fe59a9fc" 'ext4))
    (type "ext4")
    (flags '(no-atime)))
      
   ;; sirius - primary storage
   (file-system
    (mount-point "/public/hdd1")
    (device (uuid "46630077-0942-4f80-add4-584a0c53838a" 'ext4))
    (type "ext4")
    (flags '(no-atime))
    (needed-for-boot? #f)
    (skip-check-if-unavailable? #t)
    (create-mount-point? #t))
   
   ;; rigel - secondary storage
   (file-system
    (mount-point "/public/hdd2") 
    (device (uuid "bf91bd86-c9ea-4675-95a8-cc172afdec29" 'ext4))
    (type "ext4")
    (flags '(no-atime))
    (needed-for-boot? #f)
    (skip-check-if-unavailable? #t)
    (create-mount-point? #t))
   
   %base-file-systems))
