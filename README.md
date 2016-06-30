# Thunder Development Tools

----------

## Code Style Guidelines

Thunder code style guidelines are in agreement with Drupal code styles. For general validation of files is used [Drupal Coder](https://www.drupal.org/project/coder). More detailed validation of JavaScript code is made by [ESLint](http://eslint.org/) with predefined [Drupal settings](https://www.drupal.org/node/1955232).

#### Drupal Coder
In order that Drupal Coder works, following steps should be executed.

1. Install Composer (* this step can be skipped if composer already exists on system)
* Please follow [guide](https://getcomposer.org/download/) on official page
2. Install Drupal/Coder in global Composer directory
* Please follow [installation guide](https://packagist.org/packages/drupal/coder) on Packagist

Usage from command line:
```bash
# check Code for Drupal coding standards
phpcs --standard=Drupal -p <project root directory>

# autocorrect code for Drupal coding standards
phpcbf --standard=Drupal <project root directory>
```
Additionally both commands can be used with option ```--standard=DrupalPractice``` for checking defined Drupal best practices.

#### ESLint

In order that ESLint works, following steps should be executed

1. Install Node.js (* this step can be skipped if Node.js already exists on system)
* Official [guide](https://nodejs.org/en/download/package-manager/) from Node.js page should be followed
2. Install ESLint
```bash
npm install -g eslint
```

Usage from command line:
```bash
eslint <project root directory>
```

#### Thunder Guidelines Checker

This script is provided by Thunder Development Tools. It's wrapper for phpcs and eslint tools.

To initialize project with requirements execute:
```bash
vendor/bin/check-guidelines.sh --init
```
Please take in consideration that ```vendor/bin``` path could be customized in your root composer.json file.

Then some basic options for checking of code style guidelines can be used:
```bash
-cs, --phpcs            use PHP Code Sniffer with Drupal code style standard
-js, --javascript       use ESLint with usage of project defined code standard
-ac, --auto-correct     apply auto formatting with validation of code styles
```

For example to check and correct php and javascript files with auto correction:
```bash
vendor/bin/check-guidelines.sh --phpcs --javascript --auto-correct
```

----------

## Integrate Code Style checking in PHPStorm

#### Drupal Coder

1. In PHPStorm preferences search for: ```Code Sniff```
2. Select option ```Languages & Frameworks | PHP | Code Sniffer```
3. Open configuration dialog by pressing edit button [...]
4.  In Configuration dialog add new configuration or edit existing **Local**. Set correct path for **phpcs** by pressing edit button [...]. Path should be: ```<composer home directory>/vendor/bin/phpcs``` and save that settings for Code Sniffer
5. To configure usage of PHP Code Sniffer select ```Editor | Inspections```
6. Option **PHP Code Sniffer validation** should already be filtered by Search. Enable that option.
7. And for that validation procedure change **Coding standard** option to **Drupal**. (* sometimes PHPStorm doesn't recognize that coding standard has been changed if **Drupal** is preselected. It's sufficient just to select other coding standard and then put back to **Drupal**) 

After these settings are saved in PHPStorm warnings with prefix **phpcs:** will be displayed in editor.

#### ESLint

1. In PHPStorm preferences search for: ```ESLint```
2. Select option ```Languages & Frameworks | JavaScript | Code Quality Tools | ESLint```
3. Enable it

Default settings can be preserved. ESLint will automatically search for installed ```eslint``` command and also coding style configuration files from project will be used.


----------

## Git Hooks

#### Git Pre Commit Hook

To check is code valid before commit, git pre commit hook can be used with execution of thunder guideline checker script. Create script file ```.git/hook/pre-commit``` in your project folder, with following content:
```bash
#!/bin/sh
vendor/bin/check-guidelines.sh --phpcs --javascript
```
That will automatically validate files before commit and display possible problems and additionally commit will not be executed unless everything is correct and valid.