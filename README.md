# robocar-setup

Tools to init and boot robocar stack on raspberrypi boards.



## Bootstrap sdcard

 * add your ssh public key in `authorized_keys` file
 * to configure wifi, add `.secret` file with content:
```bash
WIFI_SSID="ssid"
WIFI_PASSWORD="password"
```
 * uncomment and fix `SD_CARD_*` variables in `build_sdcard.sh`
 * insert sdcard and run `build_sdcard.sh`
 
 
## Configure raspberry and  install stack

Install ansible on local host and run:
```bash
cd ansible
ansible-playbook -i hosts site.yml
``` 
