#!/usr/bin/env sh
set -e

[ -z "${TOOL}" ] && TOOL="$1"
APP_URL="$2"
CALLBACK_URL="$3"

# Handle extra args to add to final call with the tool
while [ $# -gt 0 ]
do
    case "$1" in
        # Not interesting
        --) continue
            ;;
        # Very interesting
        -*) case "$2" in
                # Another flag next --bloop=it -d
                -*) ADDEDARGS="${ADDEDARGS} $1"; shift
                    ;;
                # A flag and a space separated value --bloop it
                [a-z]*|[0-9]*|/*) ADDEDARGS="${ADDEDARGS} $1 $2"; shift 2
                    ;;
                # Nothing following just add and shift
                *) ADDEDARGS="${ADDEDARGS} $1";shift
                    ;;
            esac
            ;;
        *) shift;
            continue
            ;;
    esac
done

[ -z "${GET_TIMEOUT}" ] && GET_TIMEOUT=30
[ -z "${POST_TIMEOUT}" ] && POST_TIMEOUT=10
[ -z "${TOOL}" ] && echo "must provide tool for analysis" && exit 1
[ -z "${CURL}" ] && CURL=curl

# use a ramfs if possible for storing the app
[ -z "${TMPDIR}" ] && TMPDIR=/dev/shm

INPUT_PATH="${TMPDIR}/target.app"
case "${APP_URL}" in
  -|'')
    cat > "${INPUT_PATH}" || exit 1
    ;;
  http:*|https:*)
    ${CURL} -m ${GET_TIMEOUT} -so "${INPUT_PATH}" "${APP_URL}" || exit 1
    ;;
  *)
    [ -f "${APP_URL}" ] && cp "${APP_URL}" "${INPUT_PATH}" || exit 1
    ;;
esac

case "${CALLBACK_URL}" in
  -|--|'')
    CALLBACK_URL="";
    ;;
  http:*|https:*)
    continue;
    ;;
  *)
    CALLBACK_URL="";
    ;;
esac

if [ -n "${CALLBACK_URL}" ]; then

  [ -z "${CONTENT_TYPE}" ] && echo "must provide content type"

  ${TOOL} "${INPUT_PATH}" ${ADDEDARGS} > "${TMPDIR}/stdout" || \
    cat "${TMPDIR}/stdout" && exit 1

  exec cat "${TMPDIR}/stdout" | \
      ${CURL} -m ${POST_TIMEOUT} -s \
      -XPOST "${CALLBACK_URL}" \
      -H "Content-Type: ${CONTENT_TYPE}" \
      --data-binary @-
else
  exec ${TOOL} "${INPUT_PATH}" ${ADDEDARGS};
fi
