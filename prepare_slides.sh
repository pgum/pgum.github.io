#!env bash
shopt -s nullglob
format=${1:-pptx} #pdf or pptx
from=${2:-./slides/}
to=${3:-build/$format}
gittag=$(git tag --list | sort --reverse | head -n 1)
suffix=$gittag
echo Building from $from for format $format \(into: $to\). Version $gittag
mkdir -p $to
for file in $from*.md
do
  name=${file%.md}
  title=${name#$from}
  prerelease_filename=${title}.${suffix}.md
  src_filepath=${from}${prerelease_filename}
  cat ${from}header.tpl $file > $src_filepath
  echo -e "Creating: $to/${prerelease_filename%.md}.$format \tfrom: $src_filepath"
  npx marp --$format --allow-local-files --output $to/${prerelease_filename%.md}.$format $src_filepath
  rm $src_filepath
done
echo Listing of output directory $to
ls -l $to