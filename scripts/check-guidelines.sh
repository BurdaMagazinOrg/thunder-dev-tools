#!/bin/sh

#
# Check Thunder code style guidelines and apply changes
#

# Usage info
show_help() {
    cat << EOF
Usage:   ${0##*/}   [-h|--help] [-cs|--phpcs] [-js|--javascript] [-ac|--auto-correct] [-v|--verbose] [FILE|DIRECTORY]
Check Thunder code style guidelines for file or directory and optionally make auto correction

    -h, --help              display this help
    -i, --init              init required code guideline files
    -cs, --phpcs            use PHP Code Sniffer with Drupal code style standard
    -js, --javascript       use ESLint with usage of project defined code standard
    -ac, --auto-correct     apply auto formatting with validation of code styles
    -v, --verbose           verbose mode
EOF

    exit 1
}

check_eslint_requirements() {
    if ! type eslint > /dev/null 2>&1; then
        echo "\033[1m\033[31mERR: Thunder code style guideline checker requires command: eslint - please install it.\033[0m"
        exit 1
    fi

    # check used eslint config
    eslint_config=$(eslint --print-config $CHECK_DIR)
    eslint_config_size=${#eslint_config}

    if [ $eslint_config_size -lt 25000 ]; then
        echo "WARN: Thunder code style guideline is not able to detect eslint configuration files.\nPlease verify it or execute: $0 --init <project root directory>"
        exit 1
    fi
}

check_phpcs_requirements() {
    if ! type phpcs > /dev/null 2>&1 || ! type phpcbf > /dev/null 2>&1; then
        echo "\033[1m\033[31mERR: Thunder code style guideline checker requires command: phpcs and phpcbf - please install them.\033[0m"
        exit 1
    fi

    # check required phpcs standards
    supported_standards=$(phpcs -i)

    if ! [[ $supported_standards == *"Drupal"* ]] || ! [[ $supported_standards == *"DrupalPractice"* ]]; then
        echo "WARN: Thunder code style guideline is not able to detect required phpcs code standards.\nPlease verify is Drupal/Coder project installed, if not check installation guide for it."
        exit 1
    fi
}

# Init required thunder code guidelines files
init_guideline_files() {
    # get exact location of script - that will be used as path to get required configuration files
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    SCRIPT_PATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

    if [ ! -f $SCRIPT_PATH/../configs/.eslintrc ] || [ ! -f $SCRIPT_PATH/../configs/.eslintignore ]; then
        echo "WARN: Thunder code style guideline is not able to detect required files for initailization."
        exit 1
    fi

    echo "Init Thunder Guidelines"

    if [ ! -f $CHECK_DIR/.eslintrc ]; then
        echo "... symlink .eslintrc"
        ln -s $SCRIPT_PATH/../configs/.eslintrc $CHECK_DIR/.eslintrc
    else
        echo "... skipping init for .eslintrc"
    fi

    if [ ! -f $CHECK_DIR/.eslintignore ]; then
        echo "... symlink .eslintignore"
        ln -s $SCRIPT_PATH/../configs/.eslintignore $CHECK_DIR/.eslintignore
    else
        echo "... skipping init for .eslintignore"
    fi

    # check phpcs requirements
    check_phpcs_requirements

    # check eslint requirements
    check_eslint_requirements

    echo "DONE"
}

# initialize variables
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
CHECK_DIR="."

# parse command arguments
for i in "$@"; do
    case $i in
        -h | -\? | --help)
            show_help
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
        phpcbf --standard=Drupal $CODER_IGNORE_PATTERNS $CHECK_DIR
        phpcbf --standard=DrupalPractice $CODER_IGNORE_PATTERNS $CHECK_DIR
    fi

    # check best Drupal coding standard - this option will defined exit status
    phpcs -p --standard=Drupal $CODER_DISPLAY_OPTION $CODER_IGNORE_PATTERNS $CHECK_DIR
    CODER_EXIT_STATUS=$?

    # check best Drupal practices coding standard
    phpcs -p --standard=DrupalPractice $CODER_DISPLAY_OPTION $CODER_IGNORE_PATTERNS $CHECK_DIR
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

# End of file