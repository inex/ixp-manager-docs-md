# Settings UI

IXP Manager has a UI frontend for the `.env` configuration file, which should make day to day configuration changes easier.

## Available Settings

Not all possible `.env` settings are available in the frontend UI, however all of the common ones are.

If you need to change a setting that is not available, you can edit the `.env` as normal, and these settings will be preserved even if you make changes through the UI.

## DotEnv Syntax Support and Limitations

When using the frontend, some DotEnv features are limited, and others are enforce. 

Please note the following:

* Nested variables are not supported. I.e., you cannot do the following:

  ```
  VAR1="VALUE ONE"
  VAR2="${VAR1}"
  ```

* Any of the following, in any case, and whether quoted or not, is converted to `=true`: On, 1, True, Yes.
* Any of the following, in any case, and whether quoted or not, is converted to `=false`: Off, 0, False, No.
* Any numeric integer value, whether quoted or not, and excluding 0 and 1, is converted to an integer. Negative numbers are supported.
* Blank lines at the beginning or end of the `.env` are stripped. Blank lines with in the file are maintained.
* Full comment lines are maintained as they are.
* Comments after a variable is set are maintained, but not whitespace.
* Any single word values will have quotes removed.
* Any multi-word values will always be quoted.

### Example

The following would be parsed and saved exactly as is:

```
############################################################
############################################################
####
#### test settings
####

# Test variable and value
VAR1=value1

VAR2="a second value"
VAR2_ENABLED=true # enabled by default
VAR2_PORT=8080 # port to listen on

####
############################################################
```


## Disabling the UI Interface

You can disable the UI interface through the frontend settings in the interface itself. If you wish to disable it via the `.env` file, set the following option:

```
IXP_FE_FRONTEND_DISABLED_SETTINGS=true
```

Note that if you disable it, you can only re-enable it via editing the `.env` file directly.
