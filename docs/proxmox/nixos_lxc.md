# NixOS Container

Setting up a basic nixos container within proxmox, and optionally configuring docker.

# Resources
- [NixOS Proxmox Docs](https://nixos.wiki/wiki/Proxmox_Linux_Container)

# How To

1. Download the container template in proxmox by following the instructions on the wiki 
2. Create the CT using the new template and start the container
3. The password you set in the proxmox webui doesn't work, so change the password doing the following in the **proxmox shell** (*not the container shell*)
    ```bash
    $ pct enter <ct_id>
    $ source /etc/set-environment
    $ passwd
    ```
    Then enter your new password.
4. Create your configuration.nix
    ```
    $ nano /etc/nixos/configuration.nix
    ```
5. Paste in the configuration found on the nixos wiki.
6. Rebuild the configuration
    ```
    nix-channel --update
    nixos-rebuild switch --upgrade
    ```

# Optionally Install Docker

1. Create a docker.nix file alongside your configuration
    ```
    nano /etc/nixos/docker.nix
    ```
2. Paste in the following basic config
    ```nix
    { config, pkgs, ... }:

    {
    # Enable Docker
    virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
    };

    # Install docker-compose as a system package
    environment.systemPackages = with pkgs; [
        docker-compose
    ];
    }
    ```
3. Rebuild the config `nixos-rebuild switch --upgrade`