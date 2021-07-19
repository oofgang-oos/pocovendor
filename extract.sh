#!/usr/bin/env bash
# copyright: @indianets

test -f "$1" || { echo "bruh"; exit 1; }

################################################
# adjust the variables in this block

# path to your signapk.jar dir
signapk=../sign
# keep your signing key in the same dir
keyname=YOUR_KEY_NAME

# directory in which you want to move zips
wwwpath=/path/to/the/www/dir
# username of www user
wwwuser=username
# URL assciated with www directory
httpurl=https://url-of-the.download/location

# to append to both kind of zips
vendfw="vendor-firmware"
fwonly="firmware-only"

#################################################

zipname=$1
timestamp="$(date -r $zipname)"
releasedate="$(date -d "$timestamp" +%F)"

miuitype=$(echo "$zipname" | cut -d'_' -f2 | sed 's/Global//')
miuiver=$(echo "$zipname" | cut -d'_' -f3 | cut -d'.' -f1-4)
androidver=$(echo "$zipname" | cut -d'_' -f5 | sed 's/.zip//')
name="${miuitype}_${miuiver}_$androidver"

rm -rfv $name
mkdir -pv $name $name/orig

cd $name/orig
unzip ../../$zipname META-INF/com/google/android\* firmware-update\* vendor.\*
cd ../

usheader='# @pocovendor by @indianets
ui_print("                                ");
ui_print("--------------------------------");
ui_print("                                ");
ui_print("   @pocovendor by @indianets    ");
ui_print("                                ");
ui_print("--------------------------------");
ui_print("                                ");'

usfooter='# @pocovendor by @indianets
ui_print("                                ");
ui_print("--------------------------------");
ui_print("                                ");
ui_print(" thank you! follow @pocovendor  ");
ui_print("                                ");
ui_print("        !! Warning !!           ");
ui_print(" Only download from @pocovendor ");
ui_print(" Unauthorized places modify zip ");
ui_print(" which could harm your phone    ");
ui_print("                                ");
ui_print("--------------------------------");
ui_print("                                ");
set_progress(1.000000);'

usvendor='# @pocovendor by @indianets
show_progress(0.700000, 100);
ui_print("Patching vendor image unconditionally...");
block_image_update("/dev/block/bootdevice/by-name/vendor", package_extract_file("vendor.transfer.list"), "vendor.new.dat.br", "vendor.patch.dat") ||
  abort("E2001: Failed to update vendor image.");'

usfirmware='# @pocovendor by @indianets
show_progress(0.700000, 10);
ui_print("Patching firmware images...");
package_extract_file("firmware-update/abl.elf", "/dev/block/bootdevice/by-name/abl_a");
package_extract_file("firmware-update/abl.elf", "/dev/block/bootdevice/by-name/abl_b");
ui_print("Patching vbmeta dtbo logo binimages...");
package_extract_file("firmware-update/cmnlib64.img", "/dev/block/bootdevice/by-name/cmnlib64_a");
package_extract_file("firmware-update/aop.img", "/dev/block/bootdevice/by-name/aop_a");
package_extract_file("firmware-update/devcfg.img", "/dev/block/bootdevice/by-name/devcfg_a");
package_extract_file("firmware-update/qupfw.img", "/dev/block/bootdevice/by-name/qupfw_a");
package_extract_file("firmware-update/tz.img", "/dev/block/bootdevice/by-name/tz_a");
package_extract_file("firmware-update/storsec.img", "/dev/block/bootdevice/by-name/storsec_a");
package_extract_file("firmware-update/keymaster.img", "/dev/block/bootdevice/by-name/keymaster_a");
package_extract_file("firmware-update/bluetooth.img", "/dev/block/bootdevice/by-name/bluetooth");
package_extract_file("firmware-update/xbl.img", "/dev/block/bootdevice/by-name/xbl_a");
package_extract_file("firmware-update/modem.img", "/dev/block/bootdevice/by-name/modem");
package_extract_file("firmware-update/xbl_config.img", "/dev/block/bootdevice/by-name/xbl_config_a");
package_extract_file("firmware-update/dsp.img", "/dev/block/bootdevice/by-name/dsp");
package_extract_file("firmware-update/logo.img", "/dev/block/bootdevice/by-name/logo");
package_extract_file("firmware-update/cmnlib.img", "/dev/block/bootdevice/by-name/cmnlib_a");
package_extract_file("firmware-update/hyp.img", "/dev/block/bootdevice/by-name/hyp_a");'

uslocation="./orig/META-INF/com/google/android/updater-script"
ustop="$(head -2 $uslocation)"

cp -av $uslocation ./updater-script

echo "$ustop"       >  $uslocation
echo "$usheader"    >> $uslocation
echo "$usfirmware"  >> $uslocation
echo "$usfooter"    >> $uslocation
cd ./orig/
zip -rv ../unsigned-$name-$fwonly.zip META-INF firmware-update
cd ../

echo "$ustop"       >  $uslocation
echo "$usheader"    >> $uslocation
echo "$usvendor"    >> $uslocation
echo "$usfirmware"  >> $uslocation
echo "$usfooter"    >> $uslocation
cd ./orig/
zip -rv ../unsigned-$name-$vendfw.zip META-INF firmware-update vendor.*
cd ../

mv -fv ./updater-script $uslocation
cd ../

echo "Signing $fwonly"
LD_LIBRARY_PATH=$signapk/ java -jar $signapk/signapk.jar -a 4 --min-sdk-version 28 $signapk/$keyname.pem $signapk/$keyname.pk8 "$name/unsigned-$name-$fwonly.zip" "$name/$name-$fwonly.zip"
echo "Signing $vendfw"
LD_LIBRARY_PATH=$signapk/ java -jar $signapk/signapk.jar -a 4 --min-sdk-version 28 $signapk/$keyname.pem $signapk/$keyname.pk8 "$name/unsigned-$name-$vendfw.zip" "$name/$name-$vendfw.zip"

ls -l $name/*.zip
rm -fv $name/unsigned-*.zip
touch -d "$timestamp" $name/$name-*.zip

cp -av $name/$name-*.zip $wwwpath/
chown $wwwuser:$wwwuser $wwwpath/$name-*.zip

ls -l $wwwpath/$name-*.zip

echo -e "\nTelegram Post"
echo -e "Released: $releasedate"
echo -e "$name-$fwonly.zip [$(du -sh $name/$name-$fwonly.zip | awk '{print $1}')]"
echo -e "$name-$vendfw.zip [$(du -sh $name/$name-$vendfw.zip | awk '{print $1}')]"
echo -e "\nLinks\n"
echo -e "$httpurl/$name-$fwonly.zip"
echo -e "$httpurl/$name-$vendfw.zip"
echo -e "\n"
