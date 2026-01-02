# Setting up & Locking Down a New VPS

First things to do when setting up a new VPS. For this example, I'm using a VPS running Debian 13 (Trixie).

# Resources
- [Syntax Youtube - Selfhost 101](https://youtu.be/Q1Y_g0wMwww?si=JhnX8yDgjC37uYbp)

# How To


1. Run updates with ``apt update`` & ``apt upgrade``

2. Install sudo if not installed with ``apt install sudo``

3. Change root password with ``passwd``

4. Add a new user with ``adduser {username}``

5. Add the new user to sudo'ers group: ``adduser {username} sudo`` or ``usermod -aG sudo {username}``

6. Setup key based SSH logins (Do the following on your personal PC)
    
    1. Generate SSH Keys if you haven't already: ``ssh-keygen -t ed25519``
    2. Copy the keys over to the VPS: ``ssh-copy-id {username}@{VPS-ip-address}``

7. Disable password login & root login.
    
    ```
    > sudo nano /etc/ssh/sshd_config

    Change "PasswordAuthentication" from "yes" to "no"
    Change "PermitRootLogin" to "no"

    > sudo service ssh restart
    ```

8. Install unattended-upgrades:

    ```bash
    > sudo apt install unattended-upgrades
    > sudo dpkg-reconfigure unattended-upgrades
    ```
