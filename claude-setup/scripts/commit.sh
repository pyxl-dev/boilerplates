#!/bin/bash

# /commit - Intelligent Conventional Commit Helper
# Usage: commit.sh [type] [description] or commit.sh [description]

commit_with_branch() {
    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
    
    echo -e "${BLUE}🚀 Conventional Commit Helper${NC}"
    echo "================================"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Not in a git repository${NC}"
        return 1
    fi
    
    # Check for staged changes
    if git diff --cached --quiet; then
        echo -e "${YELLOW}⚠️  No staged changes found${NC}"
        echo "Current status:"
        git status --short
        echo ""
        echo "Please stage files with: git add <files>"
        return 1
    fi
    
    # Get current branch
    BRANCH=$(git branch --show-current)
    if [ -z "$BRANCH" ]; then
        BRANCH="detached-head"
    fi
    
    echo -e "📋 Branch: ${GREEN}$BRANCH${NC}"
    
    # Show staged files
    echo -e "📁 Staged files:"
    git diff --cached --name-only | sed 's/^/  - /'
    echo ""
    
    # Parse arguments
    TYPE=""
    MESSAGE=""
    
    if [ $# -eq 0 ]; then
        # Interactive mode
        echo "🤖 Interactive mode - analyzing staged files..."
        TYPE=$(detect_commit_type)
        echo -e "💡 Suggested type: ${GREEN}$TYPE${NC}"
        echo ""
        
        read -p "Enter commit type [$TYPE]: " USER_TYPE
        if [ ! -z "$USER_TYPE" ]; then
            TYPE="$USER_TYPE"
        fi
        
        read -p "Enter commit message: " MESSAGE
        
    elif [ $# -eq 1 ]; then
        # Auto-detect type from message
        MESSAGE="$1"
        TYPE=$(detect_commit_type)
        echo -e "🔍 Auto-detected type: ${GREEN}$TYPE${NC}"
        
    elif [ $# -eq 2 ]; then
        # Explicit type and message
        TYPE="$1"
        MESSAGE="$2"
        
    else
        echo -e "${RED}❌ Usage: /commit [type] [description] or /commit [description]${NC}"
        return 1
    fi
    
    # Validate inputs
    if [ -z "$TYPE" ] || [ -z "$MESSAGE" ]; then
        echo -e "${RED}❌ Error: Both type and message are required${NC}"
        return 1
    fi
    
    # Construct commit message
    if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ] || [ "$BRANCH" = "develop" ]; then
        COMMIT_MSG="$TYPE: $MESSAGE"
    else
        COMMIT_MSG="$TYPE($BRANCH): $MESSAGE"
    fi
    
    # Show preview
    echo -e "📝 Commit message preview:"
    echo -e "   ${GREEN}$COMMIT_MSG${NC}"
    echo ""
    
    # Confirm
    read -p "Proceed with commit? [Y/n]: " CONFIRM
    if [[ $CONFIRM =~ ^[Nn]$ ]]; then
        echo "❌ Commit cancelled"
        return 1
    fi
    
    # Attempt commit
    echo "🔄 Creating commit..."
    
    if git commit -m "$COMMIT_MSG"; then
        echo -e "${GREEN}✅ Commit successful!${NC}"
        echo ""
        echo "Latest commits:"
        git log --oneline -3
    else
        echo -e "${YELLOW}⚠️  Pre-commit hooks detected issues${NC}"
        echo "🔧 Attempting to fix automatically..."
        
        # Try to fix common issues
        if command -v biome &> /dev/null; then
            echo "Running biome fix..."
            npx biome check --fix --unsafe 2>/dev/null || true
        fi
        
        # Re-add any fixed files
        git add $(git diff --cached --name-only)
        
        # Retry commit
        echo "🔄 Retrying commit..."
        if git commit -m "$COMMIT_MSG"; then
            echo -e "${GREEN}✅ Commit successful after fixes!${NC}"
        else
            echo -e "${RED}❌ Commit failed. Please fix issues manually and retry${NC}"
            return 1
        fi
    fi
}

# Function to detect commit type based on staged files and patterns
detect_commit_type() {
    local staged_files=$(git diff --cached --name-only)
    local type="feat" # default
    
    # Check file patterns and content
    while IFS= read -r file; do
        case "$file" in
            *.md|README*|CHANGELOG*|docs/*)
                type="docs"
                ;;
            *.test.*|*.spec.*|test/*|tests/*|__tests__/*)
                type="test"
                ;;
            *.config.*|*.json|*.yml|*.yaml|package.json|package-lock.json)
                type="chore"
                ;;
            *.css|*.scss|*.less|*.styl)
                # Check if it's just formatting
                if git diff --cached "$file" | grep -q "^+.*format\|^+.*lint\|^+.*style"; then
                    type="style"
                else
                    type="feat"
                fi
                ;;
        esac
    done <<< "$staged_files"
    
    # Check commit message patterns in file diffs
    local diff_content=$(git diff --cached)
    if echo "$diff_content" | grep -qi "fix\|bug\|error\|issue\|patch\|resolve"; then
        type="fix"
    elif echo "$diff_content" | grep -qi "refactor\|restructure\|reorganize\|cleanup"; then
        type="refactor"
    elif echo "$diff_content" | grep -qi "add\|create\|implement\|new\|feature"; then
        type="feat"
    fi
    
    echo "$type"
}

# Main execution
commit_with_branch "$@"