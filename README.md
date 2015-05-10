# PocketPasswords: A TSV Password File Reader for iOS

PocketPasswords is a password file reader for iOS. You can put multiple
encrypted password files on your iOS device, and use the app to read them.

It is a universal app and therefore can be used on both iPhone and iPad. It is
written in both Swift and Objective-C.

You can say this is a poor person's password manager. It has a lot of
limitations. More on that later.


## History and Motivations

Earlier this year I was without my laptop for an extended period of time.
I had been using both 1Password and a
[command-line password manager](https://github.com/lukhnos/passwort) I wrote
myself to manage my passwords, but there was no way to read both password
databases on my iPad.

I was very reluctant to buy another password manager (or another version of
an existing one) for my iOS devices, and I really just needed a read-only
app so that I could travel with only my iOS devices.

Therefore I wrote this simple app.


## Limitations

This app is not a fully-featured password manager. You can't edit entries
or create new entries with it.

The app requires you to drop your encrypted TSV files via iTunes. I chose
on purpose not to support iCloud or any other sync mechanism.

Finally, the source code is not security-reviewed. Use the app at your own
risk.


## How to Use this App

Build the app and install it on your iOS device. The project file is at
`./iOS/PocketPasswords/PocketPasswords.xcodeproj`. Then you need to prepare
the password files you want to use on your device.

A plain-text password file needs to be in the TSV (tab-separated file) format.
1Password can export such files, and so I believe do many password managers.

Once you have the exported file, you need to encrypt it–you don't want to
store your password database in the clear on your iOS device. To do so,
use a Python tool (that is also written by me) called
[protectedblob](https://github.com/lukhnos/protectedblob-py). To install, run:

    pip install protectedblob

Depending on your setup, you may also need to run it with `sudo`:

    sudo pip install protectedblob

Once you have the tool, encrypt your TSV file with:

    protectedblob encrypt --input passwords.tsv --output passwords.json

Now, connect your iOS device to your computer, open iTunes, go to the Apps
tab and find a section called File Sharing. You'll find PocketPasswords
(under the name "Pocket PWD") there as an installed app. Drop the encrypted
file to the "Pocket PWD Documents" box, and iTunes will immediately sync the
file to your iOS device. There's no need to click the Sync button below for
this.

The last step is to tell the app which JSON file to use. Open the Settings
app on your iOS device, and find Pocket PWD among your installed apps. Tap the
app name, and you'll find the settings for the app. Currently there's only
one setting called "File." Put `passwords.json` (or whichever file name you
chose for the encrypted file) there.

Now the app is ready. Each time you switch to the app, it prompts you for the
encrypted TSV's passphrase. The moment you switch to another app (or bring up
e.g. Control Center by swiping up from the bottom of the screen), the app
clears the current list. When you select an entry, the app shows you the
details – like account name, URL, and so on. If the column is called
`password` in the TSV file, the password field will be redacted.

Tapping on any non-password field copies the data to the pasteboard. If you
tap on a password field, the app will ask you if you just want to reveal it
or to copy it to the pasteboard.


## Caveats

Currently, the app does not show detailed error messages. So if the password
to unlock the file is wrong, or if the file is corrupt, there's no way to know
which case it is. The app will simply silently ignore it.

The app currently requires the plaintext TSV file to start with a "Title"
field.

By default, `protectedblob` uses 65536 rounds to derive its encryption key.
This is too low ever for a 2012 iPhone 5 device (modern iOS devices are
*fast*!). I suggest you use more than that. For example:

    protectedblob encrypt --input passwords.tsv --output passwords.json --rounds 262144

Increase the number of rounds for the key derivation function. Again, even
that will take less than 3 seconds on a 2012 iPhone 5. If you use the latest
iOS devices, you want to increase that number further.

The password store as implemented in `PPStore.m` leaves much to be desired.
The biggest issue is that it creates too many intermediate strings when
reading the rows from the decrypted TSV file. It should minimize such use and
zero out the decrypted data the moment it's not needed.


## Miscellaneous

`PPStore` is written in Objective-C because it hits three pain points of
Swift: reading JSON, manipulating byte data, and crypto. I'm glad that Xcode
makes bridging the two languages relatively painless.
