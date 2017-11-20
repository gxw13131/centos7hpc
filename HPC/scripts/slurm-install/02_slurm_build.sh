#!/bin/bash
# this is 2nd stage of SLURM install: 1st is munge install, see "01_munge_master.sh"


# uncomment for 1st time munge installation
#./01_munge_master.sh


#SLURM building

## prerequisites
yum -y install openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad perl-ExtUtils-MakeMaker 

### pdsh "yum -y install openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad"


yum -y install mariadb-server mariadb-devel 


wget https://download.schedmd.com/slurm/slurm-17.02.9.tar.bz2

rpmbuild -ta slurm-*.*.*.tar.bz2

# the rpms are in /root/rpmbuild/RPMS/x86_64/*.rpm

mkdir -p /share/installs/slurm

cp /root/rpmbuild/RPMS/x86_64/*.rpm /share/installs/slurm/

cp -f ./nodes/slurm_install_nodes.sh /share/installs/slurm/
chmod +x /share/installs/slurm/slurm_install_nodes.sh

pdsh /share/installs/slurm/slurm_install_nodes.sh
