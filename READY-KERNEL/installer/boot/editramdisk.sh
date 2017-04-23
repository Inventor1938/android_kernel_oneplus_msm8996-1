#!/sbin/sh

# Script originaly created by flar2@github.com
# https://github.com/flar2/android_kernel_oneplus_msm8996

mkdir /tmp/ramdisk
cp /tmp/boot.img-ramdisk.gz /tmp/ramdisk/
cd /tmp/ramdisk/
gunzip -c /tmp/ramdisk/boot.img-ramdisk.gz | cpio -i
rm /tmp/ramdisk/boot.img-ramdisk.gz
rm /tmp/boot.img-ramdisk.gz

# Don't force encryption
if  grep -qr forceencrypt /tmp/ramdisk/fstab.qcom; then
	sed -i "s/forceencrypt/encryptable/" /tmp/ramdisk/fstab.qcom
fi

# Start dorimanx script
if [ $(grep -c "import /init.dorimanx.rc" /tmp/ramdisk/init.rc) == 0 ]; then
	sed -i "/import \/init\.environ\.rc/aimport /init.dorimanx.rc" /tmp/ramdisk/init.rc
fi

# Don't let bfq become default scheduler
if [ $(grep -c "setprop sys.io.scheduler \"bfq\"" /tmp/ramdisk/init.qcom.power.rc) == 1 ]; then
	sed -i "/setprop sys\.io\.scheduler \"bfq\"/d" /tmp/ramdisk/init.qcom.power.rc
fi

# Copy modules to ramdisk
cp /tmp/modules.img /tmp/ramdisk/
chmod 0644 /tmp/ramdisk/modules.img

# mount modules image
if [ $(grep -c "modules.img" /tmp/ramdisk/init.qcom.rc) == 0 ]; then
	sed -i "/on boot/a\ \ \ \ mount ext4 loop\@\/modules\.img \/system\/lib\/modules noatime ro" /tmp/ramdisk/init.qcom.rc
fi

# allow mounting
chmod 0750 /tmp/sepolicy-inject
/tmp/sepolicy-inject -s init -t system_file -c dir -p mounton -P /tmp/ramdisk/sepolicy

# copy dorimanx scripts
cp /tmp/init.dorimanx.rc /tmp/ramdisk/init.dorimanx.rc
chmod 0750 /tmp/ramdisk/init.dorimanx.rc

# pack ramdisk
find . | cpio -o -H newc | gzip > /tmp/boot.img-ramdisk.gz
rm -r /tmp/ramdisk
