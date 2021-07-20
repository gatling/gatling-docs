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
ENVIRONMENT=production
COMMAND="server"
WITHDRAFTS=2
BASEURL=""
PREPARE=true

dir=$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

cd "$dir/.."

MYTMPDIR="$(mktemp -d)"

if [ -z "$DEBUG" ]; then
  trap 'rm -rf -- "$MYTMPDIR"' EXIT
fi

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

merge_and_delete_temp() {
  local temp_path="$1"
  local merge_path="$2"

  if [[ -f "$merge_path" ]]; then
    mkdir splitdir
    csplit --silent --elide-empty-files --prefix splitdir/part $merge_path '/^---$/' '{1}'
    frontmatter=$(yq ea 'select(di == 0) | select(fi == 0) * select(fi == 1)' "splitdir/part00" "$temp_path")
    content=$(cat splitdir/part01)
    rm -R splitdir
    cat << EOF > "$merge_path"
---
$frontmatter
$content
EOF
  else
    cp "$temp_path" "$merge_path"
  fi
  rm "$temp_path"
}

build_indexes() {
  local repo="$1"
  local branch="$2"
  local remote_dir="$3"
  local local_dir="$4"

  unversionned_section_index="content/$local_dir/_index.md"
  unversionned_section_index_temp=$(mktemp)

  REPOSITORY="$repo" BRANCH="$branch" REMOTE_DIR="$remote_dir" LOCAL_DIR="$local_dir" \
    envsubst '${REPOSITORY} ${BRANCH} ${REMOTE_DIR} ${LOCAL_DIR}' < "template/indexes/unversionned-section-index.md" > "$unversionned_section_index_temp"
  merge_and_delete_temp "$unversionned_section_index_temp" "$unversionned_section_index"
}

build_indexes_version() {
  local repo="$1"
  local branch="$2"
  local remote_dir="$3"
  local local_dir="$4"
  local version="$5"
  local latest="$6"

  cp "template/indexes/versioned-reference-index.md" "content/$local_dir/reference/_index.md"

  versionned_reference_section_index="content/$local_dir/reference/$version/_index.md"
  versioned_reference_section_index_temp=$(mktemp)

  cp "template/indexes/versioned-reference-index.md" "content/$local_dir/reference/_index.md"
  REPOSITORY="$repo" BRANCH="$branch" REMOTE_DIR="$remote_dir" LOCAL_DIR="$local_dir" VERSION="$version" LATEST="${latest:-false}" \
    envsubst '${REPOSITORY} ${BRANCH} ${REMOTE_DIR} ${LOCAL_DIR} ${VERSION} ${LATEST}' < "template/indexes/versioned-reference-section-index.md" > "$versioned_reference_section_index_temp"

  merge_and_delete_temp "$versioned_reference_section_index_temp" "$versionned_reference_section_index"

  if [[ -n $latest ]]; then
    unversionned_section_index_temp=$(mktemp)
    REPOSITORY="$repo" BRANCH="$branch" REMOTE_DIR="$remote_dir" LOCAL_DIR="$local_dir" \
      envsubst '${REPOSITORY} ${BRANCH} ${REMOTE_DIR} ${LOCAL_DIR}' < "template/indexes/unversionned-section-index.md" > "$unversionned_section_index_temp"
    merge_and_delete_temp $unversionned_section_index_temp "content/$local_dir/_index.md"

    cp "content/$local_dir/reference/$version/_index.md" "content/$local_dir/reference/current/_index.md"
  fi
}

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


drop_search_index() {
  local local_dir="$1"

  rm "content/$local_dir/search.md" || true
}

hugo_structure() {
  local repo="$1"
  local branch="$2"
  local remote_dir="$3"
  local local_dir="$4"

  fetch_doc "$repo" "$branch" "$remote_dir" "content/$local_dir"
  drop_search_index $local_dir
  build_indexes "$repo" "$branch" "$remote_dir" "$local_dir"
}

hugo_structure_version() {
  local repo="$1"
  local branch="$2"
  local remote_dir="$3"
  local local_dir="$4"
  local version="$5"
  local latest="$6"

  if [[ -n $latest ]]; then
    fetch_doc "$repo" "$branch" "$remote_dir" "content/$local_dir"
    drop_search_index $local_dir

    mkdir -p "content/$local_dir/reference/$version"
    cp -r "content/$local_dir/reference/current"/* "content/$local_dir/reference/$version"
  else
    fetch_doc "$repo" "$branch" "$remote_dir/reference/current" "content/$local_dir/reference/$version"
  fi
  build_indexes_version "$repo" "$branch" "$remote_dir" "$local_dir" "$version" "$latest"
}

install_dependencies() {
  # envsubst
  apk add gettext

  # yq
  wget https://github.com/mikefarah/yq/releases/download/v4.8.0/yq_linux_amd64.tar.gz -O - |\
    tar xz && mv yq_linux_amd64 /usr/bin/yq

  # csplit
  apk add coreutils

  # global node modules
  npm install -g postcss postcss-cli @fullhuman/postcss-purgecss purgecss-whitelister
}

prepare () {
  if [[ "$PREPARE" = true ]]; then
    clean

    echo "=====> prepare phase"

    if [[ "$DOCKER" = true ]]; then
      install_dependencies
    fi

    hugo mod get -u
    hugo mod npm pack
  
    npm install
  
    mkdir ./content || true

    #                       # repository           # branch  # remote            # local
    hugo_structure          "frontline-cloud-doc"  "main"    "content"           "enterprise/cloud"
    #                                                                                                      # version  # latest
    hugo_structure_version  "frontline-doc"        "main"    "content"           "enterprise/self-hosted"  "1.14"     true
    hugo_structure_version  "frontline-doc"        "1.13"    "content"           "enterprise/self-hosted"  "1.13"
    hugo_structure_version  "gatling"              "main"    "src/docs/content"  "gatling"                 "3.6"      true
    hugo_structure_version  "gatling"              "3.5"     "src/docs/content"  "gatling"                 "3.5"
    hugo_structure_version  "gatling"              "3.4"     "src/docs/content"  "gatling"                 "3.4"
    hugo_structure_version  "gatling"              "3.3"     "src/docs/content"  "gatling"                 "3.3"

    cp template/search.md content/search.md

  else
    echo "=====> skip prepare"
  fi
}

optimize() {
  echo "=====> optimize phase"
  node bin/optimize_search_index.js public/search/index.json utf8
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
    optimize
    ;;
  clean)
    clean
    ;;
  *)
    usage
    ;;
esac
