## 0.20.0. (December 27, 2023)

ENHANCEMENTS:

* only create `aws_backup_plan` if rules are provided (thanks @gpdenny)

## 0.19.3 (September 1, 2023)

ENHANCEMENTS:

* Add tags to `aws_iam_policy` resources

## 0.19.2 (April 28, 2023)

FIXES:

* Fix inconsistent plan role output (thanks @miachm)

## 0.19.1 (April 5, 2023)

FIXES:

* Fix dependencies between resources (thanks @dhoppe)

## 0.19.0 (February 28, 2023)

ENHANCEMENTS:

* Add support for `force-destroy` flag to backup vault (Thanks @igorzi84)
* Add new resource `aws_backup_vault_lock_configuration` (Thanks @dhoppe)


## 0.18.0 (September 30, 2022)

ENHANCEMENTS:

* Allow to set iam role name if u use labels with specific naming otherwise use predefined
* Prettier IAM policy documents
* Update pre-commits versions

Thanks @dmitrijn

## 0.17.0 (July 24, 2022)

ENHANCEMENTS:

* Update aws provider constraint (Thanks @cloudboyd)

## 0.16.0 (July 18, 2022)

ENHANCEMENTS:

* Add support for any AWS partitions (thanks @renaudhager)

## 0.15.0 (April 29, 2022)

FIXES:

* Add constraints for Terraform & AWS provider versions
* Remove provider constraints in examples

## 0.14.0 (March 3, 2022)

ENHANCEMENTS:

* Add support for AWS Backup S3 capabilities (thanks @svenlito)

## 0.13.3 (Feb 19, 2022)

ENHANCEMENTS:

* Change required provider block definition

## 0.13.2 (Feb 2, 2022)

ENHANCEMENTS:

* Update examples and READMEs for Tags and Conditions

## 0.13.1 (Jan 26, 2022)

ENHANCEMENTS:

* Update examples and READMEs

## 0.13.0 (Jan 26, 2022)

ENHANCEMENTS:

* Add `not_resources` and `condition` support for selections
* Update complete example & READMEs

## 0.12.2 (Jan 25, 2022)

FIXES:

* Fix backup selection re-creation issue (thanks @tchernomax)

## 0.12.1 (Jan 2, 2022)

FIXES:

* Fix error when missing optional vault_value (thanks @ElSamhaa)
* Align example readme with code (thanks @daniel-habib)

## 0.12.0 (July 16, 2021)

ENHANCEMENTS:

* Add multiple `copy_action` support (thanks @unni-kr)
* Add "Error creating Backup Vault" know issue in README

## 0.11.6 (May 13, 2021)

FIXES:

* Fix `selection_tags` in README

## 0.11.5 (May 5, 2021)

FIXES:

* Fix recovery_point_tags default value
* Update minimum AWS provider version to 3.20.0
* Remove know issues note in README
* Remove bash script to remove / destroy the resouses due to old reported issue

ENHANCEMENTS:

* Add notifications only on failed jobs example (thanks @iainelder)

## 0.11.4 (April 10, 2021)

FIXES:

* Fix typo in README

## 0.11.3 (April 22, 2021)

ENHANCEMENTS:

* Add pre-commit config file
* Add .gitignore file
* Update README

## 0.11.2 (April 10, 2021)

FIXES:

* Add `rule_enable_continuous_backup` variable in README

## 0.11.1 (April 10, 2021)

FIXES:

* Update complete example & README

## 0.11.0 (April 10, 2021)

ENHANCEMENTS:

* Add support for `enable_continuous_backup`
* Update examples
* Update README

## 0.10.0 (April 7, 2021)

FIXES:

* Rename `selection_tag` for `selection_tags`

## 0.9.0 (April 7, 2021)

FIXES:

* Add support for several selection tags
* Remove `selection_tag_type`, `selection_tag_key` and `selection_tag_value` in favour of a `selection_tags` list variable
* Update README and examples folder to include several selection tags examples

## 0.8.0 (April 7, 2021)

ENHANCEMENTS:

* Allows attaching an already created IAM role to the Plan (thanks @samcre)
* Update README to include Terraform rsources used

## 0.7.0 (February 28, 2021)

ENHANCEMENTS:

* Add support to AWS Backup Notifications

Based on @diego-ojeda-binbash PR

## 0.6.0 (December 6, 2020)

ENHANCEMENTS:

* Add support to activate Windows VSS

Thanks @riccardo-salamanna

## 0.5.0 (September 9, 2020)

ENHANCEMENTS:

* Add AWS Backup Service Role output

FIXES:

* Add policy for performing restores

## 0.4.1 (August 13, 2020)

FIXES:

* Fixing registry url (thanks @matthieudolci)

## 0.4.0 (August 4, 2020)

ENHANCEMENTS:

* Add option to define selections by tags only, without resource definition
* Now you can define selections with just resources, tags or boths. No need to define empty values.
* Add README to examples

UPDATES:

* Add selection by tags plan example
* Update examples

## 0.3.2 (July 20, 2020)

FIXES:

* Fix space in `completion_window` value

## 0.3.1 (April 17, 2020)

UPDATES:

* Update README to include copy_action block example

## 0.3.0 (April 17, 2020)

ENHANCEMENTS:

* Add support for Copy Action

UPDATES:

* Update completed_example to include copy_action block
* Update simple_plan_using_\* examples

## 0.2.1 (April 1, 2020)

UPDATES:

* Add Terraform logo in README

## 0.2.0 (January 30, 2020)

ENHANCEMENTS:

* Add enabled flag which avoid deploying any AWS Backup resources when set to false

FIXES:

* Fix inputs formatting in README file

## 0.1.2 (October 18, 2019)

UPDATE:

* Rename module references in README and examples

## 0.1.1 (October 18, 2019)

FEATURES:

* Add CHANGELOG
* Add LICENSE

## 0.1.0 (October 17, 2019)

FEATURES:

* Module implementation
* Add README
* Add examples
