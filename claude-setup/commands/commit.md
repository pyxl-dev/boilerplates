# /commit - Conventional Commit Helper

Automated conventional commit creator with branch name integration.

## Usage
```bash
/commit [type] [description]
/commit [description]  # auto-detects type
/commit                # interactive mode
```

## Examples
```bash
/commit feat add user authentication
/commit fix resolve login validation bug  
/commit refactor simplify chart rendering logic
/commit update documentation for API endpoints
```

## Live Implementation
The command is implemented in `/home/yoan/.claude/scripts/commit.sh` and can be used immediately:

```bash
# Run the script directly
bash /home/yoan/.claude/scripts/commit.sh

# Or create an alias
alias /commit='bash /home/yoan/.claude/scripts/commit.sh'
```

## Command Implementation

### Auto-Detection Logic
- **feat**: add, create, implement, build, introduce
- **fix**: fix, resolve, correct, repair, patch
- **refactor**: refactor, restructure, reorganize, simplify
- **docs**: document, readme, guide, comment
- **style**: format, lint, cleanup, organize
- **test**: test, spec, coverage, validation
- **chore**: update, upgrade, dependency, config

### Execution Steps
1. **Branch Detection**: Get current git branch name
2. **Status Check**: Verify staged changes exist
3. **Type Detection**: Auto-detect or use provided type
4. **Message Construction**: Format as `type(BRANCH): description`
5. **Commit Creation**: Execute git commit with proper message
6. **Validation**: Handle pre-commit hooks and conflicts

### Smart Features
- **Auto-capitalization**: Ensures proper sentence case
- **Length validation**: Keeps subject line under 72 characters
- **Scope detection**: Uses branch name as scope automatically
- **Interactive fallback**: Prompts for missing information
- **Pre-commit integration**: Handles linting and validation

### Branch Name Patterns
- `TE-1808` → `feat(TE-1808): message`
- `feature/user-auth` → `feat(feature/user-auth): message`
- `bugfix/login-issue` → `fix(bugfix/login-issue): message`
- `main` → `feat: message` (no scope for main branch)

### Error Handling
- **No staged changes**: Shows git status and guidance
- **Invalid branch**: Uses current branch or prompts
- **Pre-commit failures**: Automatically fixes and retries
- **Long messages**: Truncates or suggests body text

### Integration
- **Pre-commit hooks**: Automatically handles linting fixes
- **Multiple files**: Groups related changes intelligently
- **Conflict resolution**: Provides clear next steps
- **History awareness**: Suggests similar recent commit patterns