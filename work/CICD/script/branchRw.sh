#tr!/bin/bash
set -e
svn_path=$1
[[ $svn_path =~ .*/$  ]] && svn_path=${svn_path:0:$((${#svn_path}-1))}

branch=$(echo $svn_path|awk -F/ '{print  $(NF-1)}')
system=$(echo $svn_path|awk -F/ '{print  $NF}')
file_path=${branch}'\/'${system}\]

authzFile="/data/svn/authz"
readOnlyFile="/data/svn/config/readOnly.set"


for user in $(sed -rn "/${file_path}/,/^$/p"  ${readOnlyFile}  | grep -v  ${file_path} )
do

  sed -i "/${file_path}/,/^$/ {/${user}=/d}"  ${authzFile}

done


sed -i "/${file_path}/,/^$/  s/=r$/=rw/"   ${authzFile}


for user in $(sed -rn "/${file_path}/,/^$/p"  ${readOnlyFile}  | grep -v  ${file_path} )
do
  sed -i "/${file_path}/a${user}=r"   ${authzFile}
done

