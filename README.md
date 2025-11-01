# daub-shim
daub as a shim
### Build Instructions
1) Clone the repo: <br />
```
git clone https://github.com/Moonsploit/daub-shim.git
cd daub-shim/builder/
```

2) Run the builder: <br />
```
sudo bash builder.sh board
```

### Prebuilts
https://dl.snerill.org/daub

### Booting a daub shim
After downloading/building a daub shim, download & open the [Chrome Recovery Utility](https://chromewebstore.google.com/detail/chromebook-recovery-utili/pocpnlppkickgojjlmhdmidojbmbodfm?pli=1). <br />
![image](https://kxtz.dev/reco-util.png)
<br />
Click the Settings icon in the top right, and select Use Local Image. Select the daub shim, and then select your usb drive/sd card.

After it is done flashing, go on your chromebook and enter developer mode, then go back to recovery mode and plug in the daub drive and press esc+↻+⏻ to boot the shim.

### CREDITS:
[Kxtzownsu](https://github.com/kxtzownsu) - creating kvs builder

[HarryTarryJarry](https://github.com/HarryTarryJarry) - creating daub script
