# ckaub-shim
ckaub as a shim
### Build Instructions
1) Clone the repo: <br />
```
git clone https://github.com/Moonsploit/ckaub-shim.git
cd ckaub-shim/builder/
```

2) Make sure you have the following dependicies installed: <br />
```
gdisk e2fsprogs
```

3) Run the builder: <br />
```
sudo bash builder.sh <raw-shim.bin>
```

### Prebuilts
https://dl.snerill.org/ckaub

### Booting a ckaub shim
After building or downloading a ckaub shim, download & open the [Chrome Recovery Utility](https://chromewebstore.google.com/detail/chromebook-recovery-utili/pocpnlppkickgojjlmhdmidojbmbodfm?pli=1). <br />
![image](https://kxtz.dev/reco-util.png)
<br />
Press the settings icon in the top right, and press "Use Local Image". Select your ckaub shim, and then select your target usb drive or sd card.

After it is done flashing, go to your target chromebook and enter developer mode. Then plug in the quicksilver drive and press ESC+REFRESH+POWER to boot the shim.

### RAW SHIMS:
https://dl.fanqyxl.net/ChromeOS/Raw%20Shims/
https://cros.download/shims

### CREDITS:
Kxtzownsu - creating kvs builder, original idead for ckaub

crosbreaker - creating ckaub

Moon - implementing ckaub functionality into a shim
