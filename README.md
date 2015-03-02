# HelpMeSee

VNC Reverser for providing support. Forked from Gitso - original prject at <https://code.google.com/p/gitso/>

I am forking this project to Github under the new name "HelpMeSee" since the original project has not been developed since 2010. The Gitso project's original roadmap for a 0.8 version will not be adhered to, since I haven't all the tools to test the features and little interest in them personally - hence the new name and new direction.

NATPMP support will be dropped, easy SSH tunnelling and setup will be added.

Instead of this, reverse tunnel management will be added as part of the Linux and Mac versions (HelpMeSee proper), and the Gitso UI will be altered to include easy access to turning remote tunnels on and off from within Gitso. Support will first be for Linux and Mac, Windows will follow as soon as I can get the build working and reverse tunneling set up properly.

Beyond that, there are no additional plans as of yet. Suggestions welcome! <https://twitter.com/helpUseIT>

## Building Gitso

The following notes are from the original project. They have yet to be tested, and updated for a more recent version of Python.

### Building on Linux

We currently support building Gitso on Ubuntu, Fedora and OpenSUSE.

From within the src directory:

* Update hosts.txt to have preset options for the client. Hosts are comma separated and optional.
* Run:./makegitso.sh [--source, --opensuse, --fedora] 

#### Fedora

You will first need to install the following:

  yum install subversion
  yum install rpmdevtools 

#### Notes

We also have the scripts working on CentOS, but CentOS 5.2 doesn't include wxWidgets. If you know differently, please let me know.
Currently the stand-alone version is automatically made if you're on Ubuntu, that will probably change at some point. There's no technical reason why it couldn't be done from the other POSIX systems... 

#### Examples

http://www.joneslinux.com/wordpress/?p=142 

### Building on Windows

We currently support Windows XP and higher.

Install:
* Python 2.5 <http://www.python.org/download/releases/2.5/>
* py2exe <http://www.py2exe.org/>
* python <http://www.python.org/download/>
* wxwidgets <http://wxpython.org/>
* nsis <http://nsis.sf.net/>
* pywin32 <http://sourceforge.net/project/showfiles.php?group_id=78018&package_id=79063&release_id=661475>

From within the src directory:
* Update hosts.txt to have preset options for the client. Hosts are comma separated and optional.
* Run: `./makegitso.bat`

### Building on Mac

* Install Developer Tools (Xcode) from the OS X System CD
* Install py2app
* From the command line type:

  curl -O http://peak.telecommunity.com/dist/ez_setup.py
  sudo python ez_setup.py -U setuptools
  sudo easy_install -U py2app

From within the src directory:
* Update hosts.txt to have preset options for the client. Hosts are comma separated and optional.
* Run:./makegitso.pl --> Gitso.dmg 

#### Notes

If you get a python gdb error try typing the following at the command line:

  defaults write com.apple.versioner.python Prefer-32-Bit -bool yes 
