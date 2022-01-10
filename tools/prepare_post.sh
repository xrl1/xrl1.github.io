# Set dir
OBSIDIANDIR="/mnt/c/personal/personal_vault"

# Get dates
current_date=`date +'%Y-%m-%d'`
long_date=`date +'%Y-%m-%dT%H:%M:%S+02:00'`

post_source_path=$OBSIDIANDIR/$1.md
echo 'Creating post'
post_path=_posts/$current_date-$1.md
echo $post_path

# Insert date if doesn't set yet
sed -i "s/date: 'DATE'/date: '$long_date'/" $post_source_path

# copy post
cp $post_source_path $post_path
