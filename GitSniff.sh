#!/bin/bash

access_token=""
query=""
keyword=""
f_1=""
f_2=""
res=""
show_help() {
echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Required Options:"
    echo "-h, --help              Show help"
    echo "-at, --access-token     You GitHub access token * with proper permissions *"
    echo "-n, --query             String to search for repositories (Example: Tesla) hint: <>"
    echo "-k, --keyword           Keyword to search for in the repository code (Example: admin)"
echo ""

echo -e "If \033[1;36mGitSniff\033[0m doesn't work as attended, please contact me on twitter: \033[1;36m @whalebone71 \033[0m"
echo ""

}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -at|--access-token)
            access_token="$2"
            shift 2
            ;;
        -n|--query)
            query="$2"
            shift 2
            ;;
        -k|--keyword)
            keyword="$2"
            shift 2
            ;;
        *)
            echo "Invalid argument: $1"
            show_help
            exit 1
            ;;
    esac
done

if [[ -z "$access_token" || -z "$query" || -z "$keyword" ]]; then
    show_help
    exit 1
fi

echo -e "\033[1;36m 
   ____ _ _     ____        _ _____ _____
  / ___(_) |_  / ___| _ __ (_)  ___|  ___|
 | |  _| | __| \___ \| '_ \| | |_  | |_
 | |_| | | |_   ___) | | | | |  _| |  _|
  \____|_|\__| |____/|_| |_|_|_|   |_|

\033[0m"

names=$(curl --request GET \
--url "https://api.github.com/search/repositories?q=${query}+in:name" \
--header "Authorization: Bearer ${access_token}" -s  | jq '.items[].name' | tr -d "\".")

owners=$(curl --request GET \
--url "https://api.github.com/search/repositories?q=${query}+in:name" \
--header "Authorization: Bearer ${access_token}" -s   | grep "login" | cut -d ":" -f2 | tr -d " \ " | tr -d "\"\,")


for i in $(seq 1 $(echo $names | wc -w)); do
    name=$(echo $names | awk '{print $'$i'}')
    owner=$(echo $owners | awk '{print $'$i'}')
    response=$(curl --request GET \
    --url "https://api.github.com/search/code?q=admin:+repo:"$owner"/"$name \
    --header "Authorization: Bearer $access_token" -s)

    if [ ! -z "$response" ]; then

        total_count=$(echo $response | jq '.total_count')
        if [ "$total_count" != "null" ] && [ "$total_count" -ne 0 ]; then
            echo -e "\033[1;92mFound\033[0m keyword \033[1;34m$keyword\033[0m in repository \033[1;32m$owner/$name:\033[0m"

            echo ""
            for item in $(echo $response | jq -r '.items[] | @base64'); do
                _jq() {
                    echo ${item} | base64 --decode | jq -r ${1}
                }
                echo  "-------------"
                echo  ""
                echo -e "\033[93mPath:\033[0m $(_jq '.path')"
                 f_1=$(_jq '.url')
           f_2=$(curl -s $f_1 | jq -r '.download_url')
           res=$(curl -s $f_2 | grep "$keyword")
            echo ""
            echo -e "\033[92m$res\033[0m"

            done
            echo ""
        else
            echo "+++++"
            echo -e "\033[1;31mNot found in repository\033[0m: $owner/$name"
            echo "+++++"
            echo ""

        fi

    fi
    sleep 1
done
