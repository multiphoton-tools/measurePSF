
What is mpqc.settings.default_settings?
The default settings file is used to make the initial settings YML. If the user creates a setting with an invalid value, it is corrected
based on the default file. Do not edit this file unless you know what you are doing (e.g. you are fixing bugs or adding settings).

How are settings tested?
The function mpqc.settings.checkSettingsAreValid uses the function handles from second output arg of mpqc.settings.default_settings
to test settings.
