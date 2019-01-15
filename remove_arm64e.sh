#put this file inside SwiftSupport folder then move it back to original place
for d in ./iphoneos/* ; do
    sudo lipo $d  -remove arm64e -output $d
    file $d
done
