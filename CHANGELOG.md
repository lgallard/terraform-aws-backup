# Changelog

All notable changes to this project will be documented in this file.


## [0.34.0](https://github.com/lgallard/terraform-aws-backup/compare/0.33.0...0.34.0) (2025-07-28)


### Features

* migrate from Dependabot to Renovate for better Terraform support ([#185](https://github.com/lgallard/terraform-aws-backup/issues/185)) ([e9ed95b](https://github.com/lgallard/terraform-aws-backup/commit/e9ed95b41c00e9d6040f1ada441e3d96f0a649f9))

## [0.33.0](https://github.com/lgallard/terraform-aws-backup/compare/0.32.0...0.33.0) (2025-07-23)


### Features

* add automatic v-prefix removal from release titles ([#183](https://github.com/lgallard/terraform-aws-backup/issues/183)) ([8e6e93e](https://github.com/lgallard/terraform-aws-backup/commit/8e6e93e755201b76e9382f21fb1437fe073367bc))

## [0.32.0](https://github.com/lgallard/terraform-aws-backup/compare/0.31.0...0.32.0) (2025-07-23)


### Features

* add release-please configuration ([#181](https://github.com/lgallard/terraform-aws-backup/issues/181)) ([d9492f8](https://github.com/lgallard/terraform-aws-backup/commit/d9492f8c1a34322f46ed61fb13896d8dc41fc5de))

## [0.31.0](https://github.com/lgallard/terraform-aws-backup/compare/0.30.6...0.31.0) (2025-07-23)


### Features

* add claude code review workflow ([#179](https://github.com/lgallard/terraform-aws-backup/issues/179)) ([a3b25eb](https://github.com/lgallard/terraform-aws-backup/commit/a3b25eb204d119286f0ed2c112bbf3acc723f5ae))

## [0.30.6](https://github.com/lgallard/terraform-aws-backup/compare/0.30.5...0.30.6) (2025-07-17)


### Bug Fixes

* Handle null values in dynamic for_each blocks in selection.tf ([#175](https://github.com/lgallard/terraform-aws-backup/issues/175)) ([54484af](https://github.com/lgallard/terraform-aws-backup/commit/54484afd3078c29ac4558512f1bf339f1441ef5a))

## [0.30.5](https://github.com/lgallard/terraform-aws-backup/compare/0.30.4...0.30.5) (2025-07-16)


### Bug Fixes

* Correct terraform formatting in iam.tf ([0342cd5](https://github.com/lgallard/terraform-aws-backup/commit/0342cd5a9caa1cf6415be27bde70dd280d2a94a5))

## [0.30.4](https://github.com/lgallard/terraform-aws-backup/compare/0.30.3...0.30.4) (2025-07-16)


### Bug Fixes

* Resolve IAM for_each invalid argument error ([#168](https://github.com/lgallard/terraform-aws-backup/issues/168)) ([49a5434](https://github.com/lgallard/terraform-aws-backup/commit/49a543404a73e81ecb9a655116aa9e38c304c139))

## [0.30.3](https://github.com/lgallard/terraform-aws-backup/compare/0.30.2...0.30.3) (2025-07-16)


### Bug Fixes

* Resolve conditions variable type error in backup selections ([#170](https://github.com/lgallard/terraform-aws-backup/issues/170)) ([d83a5cf](https://github.com/lgallard/terraform-aws-backup/commit/d83a5cf9ed34c52e972fb49d45c6308b5fb3c580))

## [0.30.2](https://github.com/lgallard/terraform-aws-backup/compare/0.30.1...0.30.2) (2025-07-13)


### Bug Fixes

* Correct output references in cost_optimized_backup example ([#166](https://github.com/lgallard/terraform-aws-backup/issues/166)) ([28e24cb](https://github.com/lgallard/terraform-aws-backup/commit/28e24cb81fe6fa3f5e99a9ae19f0d566689400f8))

## [0.30.1](https://github.com/lgallard/terraform-aws-backup/compare/0.30.0...0.30.1) (2025-07-13)


### Bug Fixes

* Add missing cold_storage_after validations for plans and rules variables ([#164](https://github.com/lgallard/terraform-aws-backup/issues/164)) ([7b99f8b](https://github.com/lgallard/terraform-aws-backup/commit/7b99f8b1842a842b424de910d0c18ab4ba60c694))

## [0.30.0](https://github.com/lgallard/terraform-aws-backup/compare/0.29.0...0.30.0) (2025-07-12)


### Features

* Implement performance optimizations and comprehensive examples (Issues [#122](https://github.com/lgallard/terraform-aws-backup/issues/122) & [#123](https://github.com/lgallard/terraform-aws-backup/issues/123)) ([#158](https://github.com/lgallard/terraform-aws-backup/issues/158)) ([18a163f](https://github.com/lgallard/terraform-aws-backup/commit/18a163fde2162db1b53fabfb873bf24c492a9a08))

## [0.29.0](https://github.com/lgallard/terraform-aws-backup/compare/0.28.0...0.29.0) (2025-07-12)


### Features

* Comprehensive Code Quality & Structure Improvements (Issues [#121](https://github.com/lgallard/terraform-aws-backup/issues/121) & [#125](https://github.com/lgallard/terraform-aws-backup/issues/125)) ([#155](https://github.com/lgallard/terraform-aws-backup/issues/155)) ([22cc323](https://github.com/lgallard/terraform-aws-backup/commit/22cc323a04c6c06a2149bea29944540a38ab8724))

## [0.28.0](https://github.com/lgallard/terraform-aws-backup/compare/0.27.0...0.28.0) (2025-07-11)


### Features

* Complete comprehensive documentation and enhanced input validation ([#119](https://github.com/lgallard/terraform-aws-backup/issues/119) [#120](https://github.com/lgallard/terraform-aws-backup/issues/120)) ([#153](https://github.com/lgallard/terraform-aws-backup/issues/153)) ([8d7d735](https://github.com/lgallard/terraform-aws-backup/commit/8d7d7358809cf9ba9369276f159a6978c4abad7a))

## [0.27.0](https://github.com/lgallard/terraform-aws-backup/compare/0.26.2...0.27.0) (2025-07-11)


### Features

* Comprehensive security enhancements and testing improvements ([#148](https://github.com/lgallard/terraform-aws-backup/issues/148)) ([3da8bd4](https://github.com/lgallard/terraform-aws-backup/commit/3da8bd4aedaf7c4d16bf4455c61394ae76597c33))

## [0.26.2](https://github.com/lgallard/terraform-aws-backup/compare/0.26.1...0.26.2) (2025-07-11)


### Bug Fixes

* standardize AWS provider configurations across examples ([c23586f](https://github.com/lgallard/terraform-aws-backup/commit/c23586fe2ad4aaafc6e22b5d612edbf1c6c54da9))

## [0.26.1](https://github.com/lgallard/terraform-aws-backup/compare/0.26.0...0.26.1) (2025-07-11)


### Bug Fixes

* Update Go dependencies to address security vulnerabilities ([#145](https://github.com/lgallard/terraform-aws-backup/issues/145)) ([cae39f8](https://github.com/lgallard/terraform-aws-backup/commit/cae39f84682a26d8bef078814bbba36686bd8964))

## [0.26.0](https://github.com/lgallard/terraform-aws-backup/compare/0.25.0...0.26.0) (2025-07-11)


### Features

* Add retry logic for transient AWS API failures in tests ([#141](https://github.com/lgallard/terraform-aws-backup/issues/141)) ([4aff8eb](https://github.com/lgallard/terraform-aws-backup/commit/4aff8eb34ba46fdde96a70df03ce825b91537b95)), closes [#132](https://github.com/lgallard/terraform-aws-backup/issues/132)

## [0.25.0](https://github.com/lgallard/terraform-aws-backup/compare/0.24.1...0.25.0) (2025-07-11)


### Features

* Implement comprehensive testing and CI/CD pipeline ([#131](https://github.com/lgallard/terraform-aws-backup/issues/131)) ([4047912](https://github.com/lgallard/terraform-aws-backup/commit/40479124432ea4506e1add512c3284b0a12492b4))

## [0.24.1](https://github.com/lgallard/terraform-aws-backup/compare/0.24.0...0.24.1) (2025-06-28)


### Bug Fixes

* Windows VSS backup validation to support all selection methods and case-insensitive EC2 detection ([#129](https://github.com/lgallard/terraform-aws-backup/issues/129)) ([bb682c3](https://github.com/lgallard/terraform-aws-backup/commit/bb682c3583931009a0dab5fc94d089b4ece2e21a))

## [0.24.0](https://github.com/lgallard/terraform-aws-backup/compare/0.23.8...0.24.0) (2025-05-30)


### Features

* Add support for multiple backup plans ([#115](https://github.com/lgallard/terraform-aws-backup/issues/115)) ([a97e915](https://github.com/lgallard/terraform-aws-backup/commit/a97e9159ea3e02df6088e2ed132f8e1521a4fb21))

## [0.23.8](https://github.com/lgallard/terraform-aws-backup/compare/0.23.7...0.23.8) (2025-03-20)


### Bug Fixes

* simplify recovery point tags assignment ([c64d98f](https://github.com/lgallard/terraform-aws-backup/commit/c64d98fcc8813814521acc0225a899ccd5852810))
* simplify recovery point tags assignment in AWS Backup plan (thanks @Edward-Ireson) ([94f4581](https://github.com/lgallard/terraform-aws-backup/commit/94f458103d504f9f67c89ae35f920da9e1b16a87))

## [0.23.7](https://github.com/lgallard/terraform-aws-backup/compare/0.23.6...0.23.7) (2025-03-19)


### Bug Fixes

* Enhance Windows VSS backup validation and add example configuration ([f2afcfd](https://github.com/lgallard/terraform-aws-backup/commit/f2afcfd559da235b1c726ae0394f6f4398e9abdb))
* Enhance Windows VSS backup validation and add example configuration ([5ff6228](https://github.com/lgallard/terraform-aws-backup/commit/5ff6228addc28b2b9227cd9dbdb6c6ad806ef969))

## [0.23.6](https://github.com/lgallard/terraform-aws-backup/compare/0.23.5...0.23.6) (2025-03-19)


### Bug Fixes

* Improve validation and configuration for AWS Backup vault ([81d9bd2](https://github.com/lgallard/terraform-aws-backup/commit/81d9bd20fe963531d0492e47651cc926cfd25daa))
* Improve validation and configuration for AWS Backup vault ([28ac0fa](https://github.com/lgallard/terraform-aws-backup/commit/28ac0faf5c873a4648b8f98927a905acd128007a))

## [0.23.5](https://github.com/lgallard/terraform-aws-backup/compare/0.23.4...0.23.5) (2025-03-18)


### Bug Fixes

* retention days validations ([4a21a68](https://github.com/lgallard/terraform-aws-backup/commit/4a21a681f2eeae92f1318b59f0739c2ae61fdf36))

## [0.23.4](https://github.com/lgallard/terraform-aws-backup/compare/0.23.3...0.23.4) (2025-03-18)


### Bug Fixes

* Add release automation configuration and fix variable default ([f9345af](https://github.com/lgallard/terraform-aws-backup/commit/f9345afbe20baee1b9c699c2e148481a6221d10e))

## 0.23.3 (March 19, 2025)

FIXES:

* Fix vault retention days validation to only require values when vault locking is enabled (#95)
* Fix conditions to re-allow flexible use of them in backup selections (#94)

## 0.23.2 (March 5, 2025)

FIXES:

* Add missing README file

## 0.23.1 (March 4, 2025)

FIXES:

* Remove local AWS provider instance to prevent conflicts with root module provider configuration (#90)

## 0.23.0. (March 2, 2025)

### Added
- Added terraform-docs template for organization_backup_policy example
- Added terraform-docs template for selection_by_conditions example
- Added terraform-docs template for selection_by_tags example
- Added SNS topic for backup notifications in multiple examples

### Changed
- Updated organization_backup_policy example to use standard backup configuration
- Updated selection_by_conditions example to use STRINGEQUALS for tag conditions
- Updated selection_by_tags example with proper tag-based selection
- Modified complete_audit_framework example to use direct configuration instead of variables
- Simplified simple_plan_using_variables example by removing unused variables
- Improved documentation across all examples with detailed descriptions and usage instructions

### Fixed
- Fixed vault retention settings in multiple examples
- Fixed selection tags format to comply with AWS Backup requirements
- Fixed recovery point tags configuration
- Fixed organization backup policy configuration
- Removed unused variables to address TFLint warnings
- Fixed copy actions configuration to prevent null value errors

## 0.22.0. (May 3, 2024)

ENHANCEMENTS:

* Add input variable to opt-out of SNS policy (thanks @henriknj)

## 0.21.0. (January 5, 2024)

ENHANCEMENTS:

* Add backup report feature (thanks @gpdenny)

## 0.20.0. (December 27, 2023)

ENHANCEMENTS:

* Add conditional for `aws_backup_plan` to avoid creation if no rules are provided (thanks @gpdenny)

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
