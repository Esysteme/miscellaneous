# install mercurial on old VM for PHP4


#say no to installing software else you will install PHP 5
yum update


wget http://docutils.sourceforge.net/docutils-snapshot.tgz
tar -xvf docutils-snapshot.tgz
cd docutils
python setup.py install

yum install ruby


cd /tmp
wget http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm
rpm -Uvh ec2-ami-tools.noarch.rpm


yum install python-devel





wget http://mercurial.selenic.com/release/mercurial-1.8.tar.gz
tar xvzf mercurial-1.8.tar.gz
cd mercurial-1.8
make install

#Python headers are required to build Mercurial
