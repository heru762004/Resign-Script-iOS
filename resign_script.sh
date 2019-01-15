echo "Welcome to Auto-Resigned Script v1.1"
echo "Created by HP (2018)"
mydir="$(cd "$(dirname "$BASH_SOURCE")" && pwd)" || {
    echo "Error getting script directory" >&2
    exit 1
}
if [ "$mydir" != "/Users/HP/Documents/iOS/RELEASE/PROD" ]; then
  mydir="/Users/HP/Documents/iOS/RELEASE/PROD";
fi
cd $mydir
pwd
echo "Downloading IPA"
curl  -O "<<URL To your IPA>>"
echo "Download complete"
rm -rf ABC.ipa
cp app.ipa ABC.ipa
rm -rf app.ipa

rm -rf Payload
rm -rf ABC-Signed.ipa
unzip -q ABC.ipa
rm -rf __MACOSX
rm -rf Payload/SwiftSupport

#reading version from template
var_a="$(cat ../template/version_template.txt)"
echo $var_a
versions=$(echo $var_a | tr ";" "\n")

a=1
for ver in $versions
do
  if [ "$a" -eq "1" ]; then
    APP_VERSION=$ver;
  fi
  if [ "$a" -eq "2" ]; then
    APP_BUILD=$ver;
  fi
  a=$(( a+1 ))
done

#modified Info.plist
#APP_VERSION=1.1.5
#APP_BUILD=4
echo "APP VERSION = ${APP_VERSION}"
echo "BUILD VERSION = ${APP_BUILD}"
read -p "enter to continue"
plutil -replace CFBundleShortVersionString -string ${APP_VERSION} ../template/Info.plist
plutil -replace CFBundleVersion -string ${APP_BUILD} ../template/Info.plist

plutil -replace CFBundleShortVersionString -string ${APP_VERSION} ../template/PROD_Appex/Info.plist
plutil -replace CFBundleVersion -string ${APP_BUILD} ../template/PROD_Appex/Info.plist

cp ../template/Info.plist Payload/ABC.app/Info.plist
cp ../template/firmware Payload/ABC.app/firmware
cp ../template/profile Payload/ABC.app/profile
cp ../template/signature Payload/ABC.app/signature
cp ../template/vkeylicensepack Payload/ABC.app/vkeylicensepack

cp ../template/GoogleService-Info.plist Payload/ABC.app/GoogleService-Info.plist

#ABC Service Appex (Extension)
#if you have extension, you need to resign the extension service too
rm -rf Payload/ABC.app/PlugIns/ABCService.appex/_CodeSignature
cp ../template/PROD_Appex/Info.plist Payload/ABC.app/PlugIns/ABCService.appex/Info.plist
cp ../template/PROD_Appex/embedded.mobileprovision Payload/ABC.app/PlugIns/ABCService.appex/embedded.mobileprovision

codesign -d -vv --entitlements entitlements.plist Payload/ABC.app/PlugIns/ABCService.appex/ABCService
#read -p "enter to continue"
cp ../template/PROD_Appex/entitlements.plist entitlements.plist
#read -p "enter to continue"
codesign -vfs "iPhone Distribution: XXXXXX" --entitlements entitlements.plist Payload/ABC.app/PlugIns/ABCService.appex/
find . -name '.DS_Store' -type f -delete
rm entitlements.plist


# Continue main ABC
#read -p "enter to continue"

rm -rf Payload/ABC.app/_CodeSignature

#read -p "enter to continue"

cp embedded.mobileprovision Payload/ABC.app/embedded.mobileprovision

codesign -f -s "iPhone Distribution: XXXXX" Payload/ABC.app/Frameworks/*

#For XCode >= 10.0, all IPA contains Frameworks which has arm64e architecture. It should be removed
cp ./SwiftSupport/iphoneos/**.dylib Payload/NETSPayApp.app/Frameworks/

rm -rf Payload/ABC.app/libswiftRemoteMirror.dylib

codesign -d -vv --entitlements entitlements.plist Payload/ABC.app/ABC
#read -p "enter to continue"
cp ../template/entitlements.plist entitlements.plist
codesign -vfs "iPhone Distribution: XXXX" --entitlements entitlements.plist Payload/ABC.app
find . -name '.DS_Store' -type f -delete
rm entitlements.plist
zip -r --symlinks ABC-Signed.ipa * -x *.sh* -x *.mobileprovision* -x *.ipa*

#upload to app store
# mydir="$(cd "$(dirname "$BASH_SOURCE")" && pwd)" || {
#     echo "Error getting script directory" >&2
#     exit 1
# }
app_id="$(cat ../template/app_id.txt)"
cd '/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Support/'
echo "Validating app..."
time ./altool --validate-app --type ios -f $mydir/ABC-Signed.ipa -u XXXXX@yahoo.com -p $app_id
echo "Uploading app..."
time ./altool --upload-app -f $mydir/ABC-Signed.ipa -u XXXXX@yahoo.com -p $app_id

#update the build number from template
echo "$APP_VERSION;$(( APP_BUILD + 1))" > $mydir/../template/version_template.txt

#backup the IPA to specific folder
cd $mydir/../IPA
mkdir "$APP_VERSION ($APP_BUILD)"
cp "$mydir/ABC-Signed.ipa" "./$APP_VERSION ($APP_BUILD)/ABC-Signed.ipa"
