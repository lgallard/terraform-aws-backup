# terraform-aws-backup

Terraform module to create [AWS Backup](https://aws.amazon.com/backup/) plans.  AWS Backup is a fully managed backup service that makes it easy to centralize and automate the back up of data across AWS services (EBS volumes, RDS databases, DynamoDB tables, EFS file systems, and Storage Gateway volumes).

## Usage

You can use this module to create a simple plan using the module's `rule_*` variables. You can also  use the `rules` and `selections` list of maps variables to build a more complete plan by defining several rules and selections at once.

Check the [examples](examples/) for the  **simple plan**, the **simple plan with list** and the **complete plan** snippets.

### Example (complete plan)

This example creates a plan with two rules and two selections at once. It also defines a vault key which is used by the first rule because no `target_vault_name` was given (null). Whereas the second rule is using the "Default" vault key.

The first selection has two assignments, the first defined by a resource ARN and the second one defined by a tag condition. The second selection has just one assignment defined by a resource ARN.

```
module "aws_backup_example" {

  source = "../modules/terraform-aws-backup"

  # Vault
  vault_name = "vault-3"

  # Plan
  plan_name = "complete-plan"

  # Multiple rules using a list of maps
  rules = [
    {
      name              = "rule-1"
      schedule          = "cron(0 12 * * ? *)"
      target_vault_name = null
      start_window      = 120
      completion_window = 360
      lifecycle = {
        cold_storage_after = 0
        delete_after       = 90
      },
      recovery_point_tags = {
        Environment = "production"
      }
    },
    {
      name                = "rule-2"
      target_vault_name   = "Default"
      schedule            = null
      start_window        = 120
      completion_window   = 360
      lifecycle           = {}
      recovery_point_tags = {}
    },
  ]

  # Multiple selections
  #  - Selection-1: By resources and tag
  #  - Selection-2: Only by resources
  selections = [
    {
      name      = "selection-1"
      resources = ["arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table1"]
      selection_tag = {
        type  = "STRINGEQUALS"
        key   = "Environment"
        value = "production"
      }
    },
    {
      name          = "selection-2"
      resources     = ["arn:aws:dynamodb:us-east-1:123456789101:table/mydynamodb-table2"]
      selection_tag = {}
    },
  ]

  tags = {
    Owner       = "backup team"
    Environment = "production"
    Terraform   = true
  }
}
```

## Inputs

| Name                                  | Description                                                                                                                         | Type            | Default  | Required |
|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|-----------------|----------|----------|
| plan\_name                            | The display name of a backup plan                                                                                                   | \`string\`      | n/a      | yes      |
| rule\_completion\_window              | The amount of time AWS Backup attempts a backup before canceling the job and returning an error                                     | \`number\`      | n/a      | yes      |
| rule\_lifecycle\_cold\_storage\_after | Specifies the number of days after creation that a recovery point is moved to cold storage                                          | \`number\`      | n/a      | yes      |
| rule\_lifecycle\_delete\_after        | Specifies the number of days after creation that a recovery point is deleted. Must be 90 days greater than \`cold\_storage\_after\` | \`number\`      | n/a      | yes      |
| rule\_name                            | An display name for a backup rule                                                                                                   | \`string\`      | n/a      | yes      |
| rule\_recovery\_point\_tags           | Metadata that you can assign to help organize the resources that you create                                                         | \`map(string)\` | \`{}\`   | no       |
| rule\_schedule                        | A CRON expression specifying when AWS Backup initiates a backup job                                                                 | \`string\`      | n/a      | yes      |
| rule\_start\_window                   | The amount of time in minutes before beginning a backup                                                                             | \`number\`      | n/a      | yes      |
| rules                                 | A list of rule maps                                                                                                                 | \`list\`        | \`\[\]\` | no       |
| selection\_name                       | The display name of a resource selection document                                                                                   | \`string\`      | n/a      | yes      |
| selection\_resources                  | An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to assign to a backup plan      | \`list\`        | \`\[\]\` | no       |
| selection\_tag\_key                   | The key in a key-value pair                                                                                                         | \`string\`      | n/a      | yes      |
| selection\_tag\_type                  | An operation, such as StringEquals, that is applied to a key-value pair used to filter resources in a selection                     | \`string\`      | n/a      | yes      |
| selection\_tag\_value                 | The value in a key-value pair                                                                                                       | \`string\`      | n/a      | yes      |
| selections                            | A list of selction maps                                                                                                             | \`list\`        | \`\[\]\` | no       |
| tags                                  | A mapping of tags to assign to the resource                                                                                         | \`map(string)\` | \`{}\`   | no       |
| vault\_kms\_key\_arn                  | The server-side encryption key that is used to protect your backups                                                                 | \`string\`      | n/a      | yes      |
| vault\_name                           | Name of the backup vault to create. If not given, AWS use default                                                                   | \`string\`      | n/a      | yes      |

## Outputs

| Name | Description |
|------|-------------|
| plan\_arn | The ARN of the backup plan |
| plan\_id | The id of the backup plan |
| plan\_version | Unique, randomly generated, Unicode, UTF-8 encoded string that serves as the version ID of the backup plan |
| vault\_arn | The ARN of the vault |
| vault\_id | The name of the vault |

## Known issues

During the developing of the module I found some issues reported to the The AWS provider:

### Related backup plan selections must be deleted prior to backup plan deletion

```
$ terraform destroy
...
module.aws_backup_example.aws_iam_policy.ab_tag_policy: Destruction complete after 2s
module.aws_backup_example.aws_iam_role.ab_role: Destruction complete after 1s

Error: error deleting Backup Plan: InvalidRequestException: Related backup plan selections must be deleted prior to backup plan deletion
	status code: 400, request id: 4a6637c8-2d46-4714-9929-4df3f694979b

```

When trying to destroy a plan, terraform complains about deleting the selections first, even though terraform tries to delete them in the right order:

This issue was reported as [_Backup Plan deletion fails randomly_](https://github.com/terraform-providers/terraform-provider-aws/issues/10414) for the AWS Provider.

This happens because thee AWS provider tries to delete the plan without waiting for the selections destroyal confirmation.

**Workaround:**

I included and script in the examples that destroys the selections first and then destroys the plan:

```
 cat terraform_destroy_aws_backup.sh

 #!/bin/sh
targets=""
for i in `terraform state list | grep "selection"`; do targets="${targets} --target=${i}"; done

# Destroy selections
terraform destroy ${targets}

# Destroy all
terraform destroy

```

### Error creating Backup Selection: IAM Role is not authorized to call tag:GetResources

```
Error: error creating Backup Selection: InvalidParameterValueException: IAM Role arn:aws:iam::111111111111:role/aws-backup-plan-complete-plan-role is not authorized to call tag:GetResources
	status code: 400, request id: 07ab775d-8885-4240-bb99-41305df969e0

  on .terraform/modules/aws_backup_example/selection.tf line 1, in resource "aws_backup_selection" "ab_selection":
   1: resource "aws_backup_selection" "ab_selection" {
```
This issue was reported as [aws_backup_selection.selection: error creating Backup Selection: InvalidParameterValueException](https://github.com/terraform-providers/terraform-provider-aws/issues/10511) for the AWS Provider.

I faced this when applying and destroying the same plan several times, for instance when I ws developing the module.

**Workaround:**

I couldn't find any workaround for this. Just destroy all wait some time and apply again.
