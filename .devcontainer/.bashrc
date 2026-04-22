
export TZ=Asia/Tokyo

cdc() {
    local branch=$(git branch --show-current 2>/dev/null)
    local type=${branch:0:5}
    local year=${branch:6:4}
    local month=${branch:10:2}
    local day=${branch:12:2}

    cd __PWD__/${year}-${month}/${day}-${type}-*
}

cdh() {
    cd __PWD__
}

gsm() {
    cd __PWD__
    git switch main
}

if [ $PWD = __PWD__ ] && [ -d .venv ]; then
    source .venv/bin/activate
fi
