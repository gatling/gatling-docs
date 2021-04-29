#!/bin/bash

usage() {
cat << EOF
usage: $0 [<options>]
       $0 <command> [<options>]

Available commands:
  clean                        delete all files and directories generated by prepare
  help                         show this help
  prepare                      only prepare repository (do not serve or publish)
  publish                      generate the site (into /public by default)
  server                       serve your current site (default to localhost:1313)

Flags:
  -p, --port int               port on which the server will listen (default 1313)
  -D, --[no]buildDrafts        include (or exclude) content marked as draft (default is including for server and excluding for publish)
      --[no]prepare            include (or exclude) the preparation phase ie. retrieve modules and sub repositories (default prepare)
EOF
}

# Default values for parameters

PORT=1313
ENVIRONMENT=development
COMMAND="server"
WITHDRAFTS=2
BASEURL=""
PREPARE=true

dir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

cd "$dir"

MYTMPDIR="$(mktemp -d)"

if [ -z "$DEBUG" ]; then
  trap 'rm -rf -- "$MYTMPDIR"' EXIT
fi

fetch_doc () {
  local repo="$1"
  local branch="$2"
  local remote_dir="$3"
  local local_dir="$4"

  rm -rf "$local_dir"
  mkdir -p "$local_dir"
  rm -rf "$MYTMPDIR/$repo" || true
  git clone "https://github.com/gatling/$repo.git" --depth 1 --branch "$2" "$MYTMPDIR/$repo"
  cp -r "$MYTMPDIR/$repo/$remote_dir"/* "$local_dir"
}

clean () {
  echo "=====> cleaning phase"
  rm -Rf \
    ./content/* \
    ./package.json \
    ./package-lock.json \
    ./go.sum \
    ./node_modules \
    ./resources 
}

prepare () {
  if [[ "$PREPARE" = true ]]; then
    clean
    echo "=====> prepare phase"
    hugo mod get -u
    hugo mod npm pack
  
    npm install
  
    mkdir ./content || true
 
    #          repo                  branch             remote_dir                  local_dir
    fetch_doc "frontline-cloud-doc" "hugo-main"        "content"                   "content/cloud"
    fetch_doc "frontline-doc"       "hugo-main"        "content"                   "content/self-hosted"
    fetch_doc "frontline-doc"       "hugo-main"        "content/reference/current" "content/self-hosted/reference/1.13"
    #fetch_doc "gatling"             "misc-96-doc-hugo" "src/sphinx"                "content/oss"
  else
    echo "=====> skip prepare"
  fi
}



POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case "$key" in
  -h|--help)
    usage
    exit 0
    ;;
  -p|--port)
    PORT="$2"
    shift
    shift
    ;;
  -D|--buildDrafts)
    WITHDRAFTS=true
    shift
    ;;
  --nobuildDrafts)
    WITHDRAFTS=false
    shift
    ;;
  --prepare)
    PREPARE=true
    shift
    ;;
  --noprepare)
    PREPARE=false
    shift
    ;;
  *) # unknown option
    POSITIONAL+=("$1")
    shift
    ;;
esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $# -gt 0 ]]; then
  COMMAND="$1"
  shift
fi

HUGO_OPTS=()
HUGO_OPTS+=(--environment "$ENVIRONMENT")

case "$COMMAND" in
  server)
    if [[ $WITHDRAFTS = 2 || "$WITHDRAFTS" = true ]]; then
      HUGO_OPTS+=(--buildDrafts)
    fi
    prepare
    HUGO_OPTS+=(--port "$PORT")
    hugo server "${HUGO_OPTS[@]}"
    ;;
  publish)
    if [[ "$WITHDRAFTS" = "true" ]]; then
      HUGO_OPTS+=(--buildDrafts)
    fi
    prepare
    hugo "${HUGO_OPTS[@]}"
    ;;
  clean)
    clean
    ;;
  *)
    usage
    ;;
esac
