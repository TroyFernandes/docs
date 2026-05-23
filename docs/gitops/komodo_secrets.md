# Commiting Secrets

Sike, this is how to encrypt those .env files before committing to git.

# Resources
- [SOPS](https://github.com/getsops/sops)
- [age](https://github.com/filosottile/age)
- [komodo periphery w/ sops + age](https://github.com/smoochy/komodo-periphery-sops-age/)

# Pre-Requisites
A working gitops workflow with Komodo

# How To

## SOPS & age
1. Install sops + age on your system. 
    - Installing both on windows is a bit more complicated. I want both sops and age available on the windows side as well, so make sure you edit your path in WSL2 to include those binaries.
2. Generate a key from **age**. It will output the public key. Make sure to keep the private key safe.
    ```bash
    ~ ❯ age-keygen -o keys.txt
    # created: 2026-05-06T21:52:28-04:00
    # public key: age1lswzfll4dgp9jdksd8095fdrfevmf39tqe9d80wszkv2tfpzly9qlqmmal
    AGE-SECRET-KEY-1DNLQRPE0G68JNCDPW932VHES64CMXWCXFJFX8882LEH546GW3DRSXJFSAG
    ```
3. Lets assume you have a git initialized dir with your compose files.
    ```bash
    ~ ❯ cd <your_repo>
    ~ ❯ nano .sops.yaml
    ```
    ```yaml
    creation_rules:
    - path_regex: \.env$
        age: age1lswzfll4dgp9jdksd8095fdrfevmf39tqe9d80wszkv2tfpzly9qlqmmal
    ```

4. Lets create a simple container to test
    ```bash
    ~ ❯ mkdir sops-test && cd sops-test
    ~ ❯ nano secrets.env
    ```
    ```bash
    TEST_SECRET=hello_from_sops
    ```
    ```bash
    ~ ❯ nano docker-compose.yml
    ```
    ```yaml
    services:
        test:
            image: alpine:latest
            command: sleep 3600
            environment:
            - TEST_SECRET 
    ```
5. Now lets encrypt the ``.env``
    ```bash
    ~ ❯ sops --encrypt secrets.env > secrets.sops.env
    ~ ❯ cat secrets.sops.env
    ```

    ```
    TEST_SECRET=ENC[AES256_GCM,data:HZ3HhoGLEfBmFmJQgCgu,iv:nESlbX+wwRxHNd6epgPuQAyT9HRCcEibq0qdxwJBcNM=,tag:zN+gmE08fqZx45dB2SzU+w==,type:str]
    sops_mac=ENC[AES256_GCM,data:GZAoA8KtOEI2XroNIPRaGGE6fZHvV6bRiHxoYZXMZg9bDowUJD6V97FpKwjnJqrhW4+y9oV01N/UdHtLfSpdI9sv/yKLH5HiCdzsWiDYQUKxyhl41aohNkQscfxq7Ql0Rp1WcnIlcA/T9Kbn7bA+G4nyF/7KPFPQ0epVt1IqJXA=,iv:ITbUSZJcjdFX0CFjZZnpZVHtr9iOtaFsCIwwdV85axU=,tag:BOhZvA9Vv71yCusa5t+/lA==,type:str]
    sops_age__list_0__map_recipient=age1lswzfll4dgp9jdksd8095fdrfevmf39tqe9d80wszkv2tfpzly9qlqmmal
    sops_age__list_0__map_enc=-----BEGIN AGE ENCRYPTED FILE-----\nYWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBXYnJINmhCUW84STRlRjFO\nSlJ1dEU1djZLZ1p0dU9MWEt2WHhtUURrSVM0CnViY3JCNG5HcjhmYUoycEptZTEv\nTnpXUHZYYnBUMGxKS1N0S29WVVdiNW8KLS0tIElLbVFsSENSeEhsK1RIT1N4WDRS\nTS94cTMzTGhZNTMyV0ZZaDlXVks0M00KufHKu3O6bKMzcKBAQA9rPaVqHauHYBDt\njgX1B9yc3qW5ZNlwR6hAvklu5v4tntsqdODhMPiM0QNcjL74fzjYAA==\n-----END AGE ENCRYPTED FILE-----\n
    sops_lastmodified=2026-05-06T23:22:22Z
    sops_unencrypted_suffix=_unencrypted
    sops_version=3.7.3

    ```
6. Edit your ``.gitignore`` to include the following:

    ```
    *.env
    !*.sops.env
    .decrypted~*
    ... rest of your gitignore
    ```

7. Push the changes

## Komodo Periphery

1. This should be a drop in replacement. Change your tag from ``ghcr.io/moghtech/komodo-periphery:2.1.2`` to ``ghcr.io/smoochy/komodo-periphery-sops-age:2.1.2``

2. Add the secret key to the periphery container however you'd like:

    ```
    # .env
    SOPS_AGE_KEY=AGE-SECRET-KEY-1DNLQRPE0G68JNCDPW932VHES64CMXWCXFJFX8882LEH546GW3DRSXJFSAG

    # compose.yml
    environment:
        SOPS_AGE_KEY: ${SOPS_AGE_KEY}
    ```
3. Deploy the container

## Komodo Web UI

1. Standard steps -> create a new stack
2. Find the ``Wrapper`` section and add in this command:

    ```
    sops exec-env secrets.sops.env '[[COMPOSE_COMMAND]]'
    ```
3. Set the dropdown called ``Apply To`` -> ``up, pull, config``
4. Deploy the stack

## Testing

1. Open a terminal in the container and echo the variable we set

    ```
    echo $TEST_SECRET
    ```
2. If you see the variable we set, then you're good!