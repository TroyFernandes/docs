# Installing Ansible on Windows through WSL

Requirements: WSL is already setup. Do all the steps below inside the WSL instance

1. Install Ansible & sshpass: ``pip install ansible`` & ``sudo apt install sshpass``

2. Generate SSH Keys and Copy:
    ```bash
    > ssh-keygen -t rsa -b 4096 
    > ssh-copy-id {username}@{remote_server_ip}
    ```

3. Create Playbook directory: ``mkdir ansible_playbooks``
4. Create Inventory file with the following:

    inventory.yml
    ```yaml
    [debian_lxc]
    192.168.1.173 ansible_ssh_user=root
    ```
5. Create playbook file with the follwing:

    test.yml
    ```yaml
    ---
    - name: Example Playbook
    hosts: debian_lxc
    tasks:
    - name: Hello World
        debug:
        msg: Hello, world!
    ```

6. Run the Playbook: ``ansible-playbook -i inventory.ini test.yml``