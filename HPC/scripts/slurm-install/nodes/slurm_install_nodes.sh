#!/bin/bash


#installing compiled slurm rpms on the nodes:

yum -y install openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad perl-ExtUtils-MakeMaker

cd /share/installs/slurm/

# change to your slurm vesion below (see rpms compiled in 1st step)

rpm -Uvh slurm-17.02.9.el7.centos.x86_64.rpm slurm-sjobexit-17.02.9.el7.centos.x86_64.rpm  slurm-devel-17.02.9.el7.centos.x86_64.rpm  slurm-perlapi-17.02.9.el7.centos.x86_64.rpm slurm-sjstat-17.02.9.el7.centos.x86_64.rpm  slurm-sql-17.02.9.el7.centos.x86_64.rpm slurm-munge-17.02.9.el7.centos.x86_64.rpm  slurm-plugins-17.02.9.el7.centos.x86_64.rpm slurm-slurmdbd-17.02.9.el7.centos.x86_64.rpm

#slurm-torque-17.02.9.el7.centos.x86_64.rpm




#rpm -Uvh 
#slurm
#slurm-devel
#slurm-munge
#slurm-perlapi
#slurm-plugins
#slurm-sjobexit
#slurm-sjstat
#slurm-torque
#slurm-slurmdbd
#slurm-sql
