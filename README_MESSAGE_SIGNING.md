# Generate a public/private key pair to verify authenticity of messages from https://updates.go.cd

The idea here is to generate a master key-pair that is locked away on a machine that is not on the network. The private key must be locked away on a non-networked machine. The public key must be known to the verifier (go).

We then generate an intermediate key-pair that will be used to sign all messages containing go version metadata. Since this key will be on a network server, there's a possibility that it gets compromised.

We use master key to sign the public key of the subordinate (aka subordinate-public-key-signed)

To verify authenticity of the version message —

  * get the master public key
  * get the subordinate public key
  * get the signed subordinate public key
  * verify that the subordinate key or the signature is not tampered using the master public key
  * get the message signature
  * get the messsage
  * verify that the message message signature is correct using the subordinate public key

Generate a master key-pair
--------------------------

1. Generate a 4096 bit master private key

    ```bash
    $ openssl genrsa -out master-private.pem -des3 4096
    ```

2. Save the private key somewhere secure (along with the passphrase)

3. Export the master public key

    ```bash
    $ openssl rsa -in master-private.pem -outform PEM -pubout -out master-public.pem
    ```

Generate a subordinate-key key-pair
-----------------------------------

1. Generate a 4096 bit master private key

    ```bash
    $ openssl genrsa -out subordinate-private.pem -des3 4096
    ```

2. Save the private key somewhere secure (along with the passphrase)

3. Export the master public key

    ```bash
    $ openssl rsa -in subordinate-private.pem -outform PEM -pubout -out subordinate-public.pem
    ```

Sign the public key of the subordinate-key using the master key
---------------------------------------------------------------

1. Sign the public key

    ```bash
    $ openssl dgst -sha512 -sign master-private.pem -binary subordinate-public.pem | openssl base64 -out subordinate-public.pem.sha512
    ```

2. Verify that the public key is signed properly

    ```bash
    $ openssl dgst -sha512 -verify master-public.pem -signature <(openssl base64 -d -in subordinate-public.pem.sha512) subordinate-public.pem
    ```

3. Save the master private key somewhere secure, we don't need it unless the subordinate-private key is compromised.

Sign message using the subordinate-private key and verify it using the master public key
----------------------------------------------------------------------------------------

1. Sign a message (MESSAGE.txt)

    ```bash
    $ openssl dgst -sha512 -sign subordinate-private.pem -binary MESSAGE.txt | openssl base64 -out MESSAGE.txt.sha512
    ```

2. Verify the message and digest is correct

    ```bash
    $ openssl dgst -sha512 -verify subordinate-public.pem -signature <(openssl base64 -d -in MESSAGE.txt.sha512) MESSAGE.txt
    ```
