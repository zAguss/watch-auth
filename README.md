WatchID Auth
-----------

WatchID Auth is a PAM (Pluggable Authentication Modules) plugin designed to enable authentication using the new <a href="https://developer.apple.com/documentation/localauthentication/lapolicy/deviceownerauthenticationwithbiometrics">kLAPolicyDeviceOwnerAuthenticationWithBiometricsOrWatch</a> API in macOS 10.15 and later. It is written in Swift

Installation
------------

1. Run the following command with `sudo` privileges to install the plugin:

    ```
    $ sudo make install
    ```

2. Edit the `/etc/pam.d/sudo` file and add the following line as the first entry:

    ```
    auth sufficient watchid-auth.so "reason=execute a command as root"
    ```

   Note: Ensure that you retain any existing `auth` configurations in the file.
