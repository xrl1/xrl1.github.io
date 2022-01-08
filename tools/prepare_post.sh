# Set dir
OBSIDIANDIR="/mnt/c/personal/personal_vault"

update_flag=$2

# Get dates
current_date=`date +'%Y-%m-%d'`
long_date=`date +'%Y-%m-%dT%H:%M:%S+02:00'`

# TODO : FIX SCRIPT
if [ "$update_flag" = "-u" ]; then
    echo 'Updating post'
    post_path=_posts/*-$1.md
    replace_with=`grep date $post_path | head -n 1`
    echo $post_path
    echo $replace_with
    cp $post_path $post_path.bak
else
    echo 'Creating post'
    post_path=_posts/$current_date-$1.md
    echo $post_path
    replace_with="date: '$long_date'"
fi
cp $OBSIDIANDIR/$1.md $post_path
sed -i "s/date: 'DATE'/$replace_with/" $post_path
