# Spell Check Guide

## Overview

This repository uses automated spell-checking to maintain high documentation quality across all markdown files and text content.

## Tools & Configuration

### Primary Tool: Typos
- **Tool**: [crate-ci/typos](https://github.com/crate-ci/typos)
- **Configuration**: `typos.toml`
- **Integration**: Pre-commit hook

### Configuration File: typos.toml

The `typos.toml` file contains:
- **Company names**: HashiCorp, etc.
- **Common misspellings**: See typos.toml for full list
- **Technical terms**: AWS, Terraform, backup-specific vocabulary
- **Infrastructure terms**: resource, configuration, environment, etc.

## Pre-commit Integration

Spell-checking runs automatically via pre-commit hooks:

```yaml
- repo: https://github.com/crate-ci/typos
  rev: v1.16.23
  hooks:
    - id: typos
      types: [markdown, text]
      args: ['--format', 'long', '--config', 'typos.toml']
      exclude: '^test_.*\.md$|.*test_formatting.*'
```

## Running Spell Check Manually

### Check all files:
```bash
pre-commit run typos --all-files
```

### Check specific file:
```bash
pre-commit run typos --files README.md
```

### Check all markdown files:
```bash
pre-commit run typos --files $(find . -name "*.md")
```

## Adding New Words

### For legitimate words flagged as typos:

1. Edit `typos.toml`:
```toml
[default.extend-words]
YourWord = "YourWord"
```

2. Test the configuration:
```bash
pre-commit run typos --all-files
```

### For actual misspellings to fix:

1. Add the correction to `typos.toml`:
```toml
[default.extend-words]
misspelling = "misspelling"
```

2. This allows the word in existing content while encouraging correct spelling in new content.

## Common Misspellings Covered

### Infrastructure Terms
- Common available misspellings → `available`
- Common backup misspellings → `backup`
- Common terraform misspellings → `terraform`
- Common resource misspellings → `resource`
- Common configuration misspellings → `configuration`

### Technical Terms
- Common environment misspellings → `environment`
- Common performance misspellings → `performance`
- Common implementation misspellings → `implementation`

## Troubleshooting

### False Positives
If a legitimate word is flagged:
1. Add it to `typos.toml` under `[default.extend-words]`
2. Use the exact spelling: `WordName = "WordName"`

### Missing Spell Check
If typos aren't being caught:
1. Verify `typos.toml` exists and is properly formatted
2. Check pre-commit hook configuration
3. Ensure file types are included (`types: [markdown, text]`)

### Configuration Not Loading
If `typos.toml` changes aren't taking effect:
1. Verify the `--config typos.toml` argument in `.pre-commit-config.yaml`
2. Clear pre-commit cache: `pre-commit clean`
3. Reinstall hooks: `pre-commit install --install-hooks`

## Best Practices

### For Contributors
1. **Run spell check before committing**:
   ```bash
   pre-commit run typos --files $(git diff --cached --name-only)
   ```

2. **Use consistent technical terminology**
3. **Check both content and variable descriptions in .tf files**
4. **Review example documentation for consistency**

### For Maintainers
1. **Regularly update typos.toml** with new technical terms
2. **Monitor for recurring misspellings** and add to configuration
3. **Keep the tool version updated** in `.pre-commit-config.yaml`
4. **Review spell-check failures** in CI/CD for patterns

## Integration with Development Workflow

### IDE Setup
Configure your IDE/editor for spell-checking:
- **VS Code**: Install Code Spell Checker extension
- **IntelliJ**: Enable built-in spell checker
- **Vim**: Use vim-spell plugin

### Git Hooks
Pre-commit hooks automatically run spell-check on:
- All staged markdown files
- Text files in the repository
- Documentation updates

### CI/CD Integration
Spell-checking is integrated into:
- Pre-commit CI workflow
- Pull request validation
- Release preparation checks

## Support

If you encounter spell-check issues:
1. Check this guide first
2. Review `typos.toml` configuration
3. Test with manual pre-commit run
4. Create an issue if problems persist

Remember: Good spelling improves documentation quality and user experience!
