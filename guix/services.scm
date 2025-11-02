(define-module (services)
  #:use-module (gnu)
  #:use-module (gnu services databases)
  #:use-module (gnu services samba)
  #:use-module (gnu packages databases)
  #:export (arisu-postgresql-service
            arisu-samba-service))

;;; PostgreSQL database service
(define arisu-postgresql-service
  (service postgresql-service-type
           (postgresql-configuration
            (postgresql postgresql-15)
            (port 5432)
            (locale "en_GB.utf8"))))

;;; Samba file sharing for local network
(define arisu-samba-service
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
