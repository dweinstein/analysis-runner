#!/usr/bin/env sh

[ -z "${TOOL}" ] && TOOL="$1"
[ -z "${TOOL}" ] && echo "must provide tool for analysis" && exit 1

OPTIND=2
while getopts ":i:o:I:" opt; do
  case $opt in
    i)
      IN_URL="${OPTARG}"
      ;;
    o)
      CALLBACK_URL="${OPTARG}"
      ;;
    I)
      INPUT_PATH="${OPTARG}"
      ;;
    --)
      break;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

shift $(( OPTIND - 1 ));

# use a ramfs if possible for storing the app
[ -z "${TMPDIR}"       ] && TMPDIR=/dev/shm
# default values if not provided
[ -z "${GET_TIMEOUT}"  ] && GET_TIMEOUT=30
[ -z "${POST_TIMEOUT}" ] && POST_TIMEOUT=10
[ -z "${CURL}"         ] && CURL=curl
[ -z "${INPUT_PATH}"   ] && INPUT_PATH="${TMPDIR}/stdin"
[ -z "${OUTPUT_PATH}"  ] && OUTPUT_PATH="${TMPDIR}/stdout"
[ -z "${STDERR_PATH}"  ] && STDERR_PATH="${TMPDIR}/stderr"

# Get the input
case "${IN_URL}" in
  -|'')
    cat - > "${INPUT_PATH}" || exit 1
    ;;
  http:*|https:*)
    ${CURL} -m ${GET_TIMEOUT} -s -o "${INPUT_PATH}" "${IN_URL}"
    ;;
  *)
    # if it's just a file, symlink it
    [ -f "${IN_URL}" ] && ln -sf "${IN_URL}" "${INPUT_PATH}"
    ;;
esac

# Process the input
if [ -z "${CALLBACK_URL}" ]; then
 exec ${TOOL} "$@" "${INPUT_PATH}"
else
  [ -z "${CONTENT_TYPE}" ] && \
  echo "must provide content type for callbacks" && exit 1
  ${TOOL} "$@" "${INPUT_PATH}" > "${OUTPUT_PATH}" 2> "${STDERR_PATH}"
  RET=$?
  [ ! ${RET} -eq 0 ] && \
    cat ${OUTPUT_PATH} >&1 && cat ${STDERR_PATH} >&2 && exit ${RET}

  exec ${CURL} -m ${POST_TIMEOUT} -s \
        -XPOST "${CALLBACK_URL}" \
        -H "Content-Type: ${CONTENT_TYPE}" \
        --data-binary @"${OUTPUT_PATH}"
fi
