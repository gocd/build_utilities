# Code signing for various OSes

Most of this is already automated. This only documents what is not automated (windows and OSX)

## OSX

* Enable remote login (SSH and VNC)
* Create a new osx account (`signer`) that will perform code signing
* Login using that account
* Create a new **EMPTY** keychain `~/Library/Keychains/codesigner.keychain`, secure it with a password
* Create a new file `~/Library/Keychains/codesigner.password` that contains this keychain password
* Import the apple code signing key into this keychain
* Make sure the code signing key's ACL allows the `/usr/bin/codesign` binary access in the keychain app
* Setup SSH keys for `signer` account to be able to login remotely

## Windows (Server 2012)

* Ensure that winrm is running (https://technet.microsoft.com/en-us/library/hh921475.aspx#BKMK_windows). After winrm is running, run the following commands

    ```
    winrm set winrm/config/client/auth @{Basic="true"}
    winrm set winrm/config/service/auth @{Basic="true"}
    winrm set winrm/config/service @{AllowUnencrypted="true"}
    ```

* Download and install Windows SDK (for windows 8)
  * https://msdn.microsoft.com/en-us/windows/desktop/bg162891.aspx
  * Setup using defaults in the installer
  * Add `signtool.exe` to path. Was in `C:\program files (x86)\windows kits\8.1\bin\x64`
* Download and install OpenSSH from MS (https://github.com/PowerShell/Win32-OpenSSH)
  * set correct path to `sftp.exe` in `sshd_config`
  * copy over the ssh keys in `~/.ssh/authorized_keys` in the `Administrator` account
* Copy over the signing keys in `.p12` format and double click it in explorer, import it using defaults. **DELETE THE KEYS after you're done.**
