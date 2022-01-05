# Set dir
OBSIDIANDIR="/mnt/c/personal/personal_vault"

# Get dates
currentDate=`date +'%Y-%m-%d'`
longDate=`date +'%Y-%m-%dT%H:%M:%S+02:00'`

post_path=_posts/$currentDate-$1.md
cp $OBSIDIANDIR/$1.md _posts/$currentDate-$1.md
sed -i "s/date: 'DATE'/date: '$longDate'/" $post_path
