#remount xfs filesystem
for i in `mount | grep xfs | grep osd | grep -v sda | awk '{print $1}'`;do
	mount -o remount,rw,noexec,nodev,noatime,nodiratime,nobarrier $i
	echo "remount xfs filesystem $i success"
done

mount | grep xfs | grep osd | grep -v sda 
