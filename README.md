# h.sh - Hosts Manager
This is a simple snippet to help manage hosts files by loading profiles to be merged into your main hosts file.

Your previous hosts file can be restored.

>I'm not a POSIX enthusiast, so fell free to fix any mistakes in this code.

## How to use
```bash 
sudo bash h.sh
```
> you need to run as **super user**
## Roadmap:
- ~~point to any hosts file~~
- ~~restore hosts file~~
- ~~load profiles with preset hosts~~
- ~~open hosts file in your favorite editor~~
- save a hosts file as a new profile
- backup hosts file
- document the code
- a better README.md

## How it works
Any file with the **\*.profile** extension in the folder **profiles/** will be listed as a valid option for file merge

This follow example... \
![an image representing a directory named "profiles" with a file named "qa.profile" inside](https://i.ibb.co/FKn1GBr/Screenshot-from-2021-05-06-21-51-47.png)

...will be listed as a valid option: \
![an image showing a console screen with the follow information: "Which profile do you want to load? [/etc/hosts] and a list of available profiles](https://i.ibb.co/Lx8r1pK/Screenshot-from-2021-05-06-22-01-00.png)

> TIP: You can create the **profiles** directory in this project root or run the script for a first time an it will be created for you :)