#!/bin/sh

#
# Check Thunder code style guidelines and apply changes
#

### initialize variables ###
ESLINT_CHECK=0
ESLINT_DISPLAY_OPTION=""
ESLINT_AUTO_CORRECT=0
ESLINT_EXIT_STATUS=0

CODER_CHECK=0
CODER_DISPLAY_OPTION="--report=summary"
CODER_AUTO_CORRECT=0
CODER_EXIT_STATUS=0
CODER_IGNORE_PATTERNS="--ignore=*/vendor/*"

MAKE_INIT=0
FORCED_COMMAND=0
CHECK_DIR="."

### Functions ###

# print usage info
show_help() {
    cat << EOF
Usage:   ${0##*/}   [-h|--help] [-cs|--phpcs] [-js|--javascript] [-ac|--auto-correct] [-v|--verbose] [FILE|DIRECTORY]
Check Thunder code style guidelines for file or directory and optionally make auto correction

Init configuration:
    -i,  --init             init required code guideline files
    -u,  --update           update required code guideline files

Using checking:
    -cs, --phpcs            use PHP Code Sniffer with Drupal code style standard
    -js, --javascript       use ESLint with usage of project defined code standard
    -ac, --auto-correct     apply auto formatting with validation of code styles

Miscellaneous:
    -v,  --verbose          verbose mode
    -h,  --help             display this help
EOF

    exit 1
}

# check requirements for proper functioning of eslint (javascript linting)
check_eslint_requirements() {
    if ! type eslint > /dev/null 2>&1; then
        echo "\033[1m\033[31mERR: Thunder code style guideline checker requires command: eslint - please install it.\033[0m"
        exit 1
    fi

    # check used eslint config
    local ESLINT_CONFIG=$(eslint --print-config $CHECK_DIR)
    local ESLINT_CONFIG_SIZE=${#ESLINT_CONFIG}

    if [ $ESLINT_CONFIG_SIZE -lt 25000 ]; then
        echo "WARN: Thunder code style guideline is not able to detect eslint configuration files.\nPlease verify it or execute: $0 --init <project root directory>"
        exit 1
    fi

    # check is used eslint config same as eslint config provided by script
    local SCRIPT_PATH=$(get_script_path)
    local PROVIDED_ESLINT_CONFIG=$(eslint --print-config -c $SCRIPT_PATH/../configs/.eslintrc $CHECK_DIR)
    if [ "x${ESLINT_CONFIG}x" != "x${PROVIDED_ESLINT_CONFIG}x" ]; then
        echo "WARN: Detected eslint code style configuration is not same as configuration provided with this script."
        exit 1
    fi
}

# check requirements for proper functioning of phpcs (PHP Code Sniffer)
check_phpcs_requirements() {
    if ! type phpcs > /dev/null 2>&1 || ! type phpcbf > /dev/null 2>&1; then
        echo "\033[1m\033[31mERR: Thunder code style guideline checker requires command: phpcs and phpcbf - please install them.\033[0m"
        exit 1
    fi

    # check required phpcs standards
    local SUPPORTED_STANDARDS=$(phpcs -i)

    if ! [[ $SUPPORTED_STANDARDS == *"Drupal"* ]] || ! [[ $SUPPORTED_STANDARDS == *"DrupalPractice"* ]]; then
        echo "WARN: Thunder code style guideline is not able to detect required phpcs code standards.\nPlease verify is Drupal/Coder project installed, if not check installation guide for it."
        exit 1
    fi
}

# get exact location of script - that will be used as path to get related configuration files
get_script_path() {
    local DIR
    local SOURCE

    local SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    local SCRIPT_PATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

    echo $SCRIPT_PATH
}

# init required Thunder code guidelines files
init_guideline_files() {
    local SCRIPT_PATH=$(get_script_path)

    if [ ! -f $SCRIPT_PATH/../configs/.eslintrc ] || [ ! -f $SCRIPT_PATH/../configs/.eslintignore ]; then
        echo "WARN: Thunder code style guideline is not able to detect required files for initailization."
        exit 1
    fi

    local COPY_FORCE_OPTION=""
    if [ $FORCED_COMMAND == 1 ]; then
        COPY_FORCE_OPTION="-f"
    fi

    echo "Init Thunder Guidelines"

    if [ $FORCED_COMMAND == 1 ] || [ ! -f $CHECK_DIR/.eslintrc ]; then
        echo "... copy .eslintrc"
        cp $COPY_FORCE_OPTION $SCRIPT_PATH/../configs/.eslintrc $CHECK_DIR/.eslintrc
    else
        echo "... skipping init for .eslintrc"
    fi

    if [ $FORCED_COMMAND == 1 ] || [ ! -f $CHECK_DIR/.eslintignore ]; then
        echo "... copy .eslintignore"
        cp $COPY_FORCE_OPTION $SCRIPT_PATH/../configs/.eslintignore $CHECK_DIR/.eslintignore
    else
        echo "... skipping init for .eslintignore"
    fi

    # check phpcs requirements
    check_phpcs_requirements

    # check eslint requirements
    check_eslint_requirements

    echo "DONE"
}

### Script ###

# parse command arguments
for i in "$@"; do
    case $i in
        -h | -\? | --help)
            show_help
        ;;
        -u | --update)
            FORCED_COMMAND=1
            MAKE_INIT=1
        ;;
        -i | --init)
            MAKE_INIT=1
        ;;
        -v | --verbose)
            ESLINT_DISPLAY_OPTION=""
            CODER_DISPLAY_OPTION=""
        ;;
        -js | --javascript)
            ESLINT_CHECK=1
        ;;
        -cs | --phpcs)
            CODER_CHECK=1
        ;;
        -ac | --auto-correct)
            ESLINT_AUTO_CORRECT=1
            CODER_AUTO_CORRECT=1
        ;;
        -?*)
            echo "WARN: Unknown option (ignored): $i\n"
            show_help
        ;;
        *)
        # last option has to be file or directory
            CHECK_DIR=$i
            break
    esac
done

if [ $MAKE_INIT == 1 ]; then
    init_guideline_files

    exit 0
fi

if [ $ESLINT_CHECK == 0 ] && [ $CODER_CHECK == 0 ]; then
    echo "WARN: at least one of validation options has to be selected"
    show_help
fi

if [ ! -f $CHECK_DIR ] && [ ! -d $CHECK_DIR ]; then
    echo "WARN: The file/directory "$CHECK_DIR" does not exist"
    show_help
fi

if [ $CODER_CHECK == 1 ]; then
    check_phpcs_requirements

    if [ $CODER_AUTO_CORRECT == "1" ]; then
        phpcbf --standard=Drupal --extensions=php,module,inc,install,test,profile,theme $CODER_IGNORE_PATTERNS $CHECK_DIR
        phpcbf --standard=DrupalPractice --extensions=php,module,inc,install,test,profile,theme $CODER_IGNORE_PATTERNS $CHECK_DIR
    fi

    # check best Drupal coding standard - this option will defined exit status
    phpcs -p --standard=Drupal --extensions=php,module,inc,install,test,profile,theme $CODER_DISPLAY_OPTION $CODER_IGNORE_PATTERNS $CHECK_DIR
    CODER_EXIT_STATUS=$?

    # check best Drupal practices coding standard
    phpcs -p --standard=DrupalPractice --extensions=php,module,inc,install,test,profile,theme $CODER_DISPLAY_OPTION $CODER_IGNORE_PATTERNS $CHECK_DIR
fi

if [ $ESLINT_CHECK == 1 ]; then
    check_eslint_requirements

    if [ $ESLINT_AUTO_CORRECT == 1 ]; then
        eslint $ESLINT_DISPLAY_OPTION $ESLINT_AUTO_CORRECT --fix $CHECK_DIR
    else
        eslint $ESLINT_DISPLAY_OPTION $ESLINT_AUTO_CORRECT $CHECK_DIR
    fi
    ESLINT_EXIT_STATUS=$?
fi

if [ $CODER_EXIT_STATUS -ne 0 ] || [ $ESLINT_EXIT_STATUS -ne 0 ]; then
    echo "\033[1m\033[31m=== Some Coding styles have to be corrected to fulfill Thunder code style guidelines ===\033[0m"

    exit 1
fi

# end of file