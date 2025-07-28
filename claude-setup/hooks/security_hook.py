#!/usr/bin/env python3
"""
Security hook to prevent dangerous command execution and sensitive file access.
Runs during PreToolUse to validate operations before execution.
"""

import json
import sys
import os
import re
from pathlib import Path

# Dangerous commands that should be blocked
DANGEROUS_COMMANDS = {
    'rm -rf /',
    'dd if=/dev/zero',
    'mkfs',
    'fdisk',
    'format',
    'del /f /s /q',
    'rd /s /q',
    ':(){ :|:& };:',  # Fork bomb
    'curl | sh',
    'wget | sh',
    'chmod 777',
    'chmod -R 777',
    'sudo su',
    'su -',
}

# Dangerous command patterns
DANGEROUS_PATTERNS = [
    r'rm\s+-rf?\s+/[^/\s]*/?$',  # rm -rf / variants
    r'dd\s+if=/dev/(zero|random|urandom)',
    r'find\s+/.*-delete',
    r'>(.*)/dev/(sd[a-z]|hd[a-z])',  # Writing to disk devices
    r'curl.*\|\s*(sh|bash|zsh)',
    r'wget.*\|\s*(sh|bash|zsh)',
    r'nc\s+-[el].*\s+/bin/(sh|bash)',  # Netcat shells
    r'python.*-c.*exec\(',  # Dangerous Python exec
    r'eval\s*\(',  # Eval functions
    r'exec\s*\(',
]

# Sensitive directories and files
SENSITIVE_PATHS = {
    '/etc/passwd',
    '/etc/shadow',
    '/etc/sudoers',
    '/root',
    '/boot',
    '/sys',
    '/proc/sys',
    '/dev',
    '/etc/ssh',
    '/home/*/.ssh',
    '~/.ssh',
    '/var/log',
    '/etc/hosts',
    '/etc/crontab',
    '/var/spool/cron',
}

# Sensitive path patterns
SENSITIVE_PATH_PATTERNS = [
    r'/etc/.*',
    r'/root/.*',
    r'/boot/.*',
    r'/sys/.*',
    r'/proc/sys/.*',
    r'/dev/.*',
    r'.*/\.ssh/.*',
    r'/var/log/.*',
    r'/var/spool/cron/.*',
    r'.*\.key$',
    r'.*\.pem$',
    r'.*\.p12$',
    r'.*\.pfx$',
    r'.*password.*',
    r'.*secret.*',
    r'.*token.*',
]

def check_dangerous_command(command):
    """Check if a command contains dangerous operations."""
    command_lower = command.lower().strip()

    # Check exact matches
    for dangerous_cmd in DANGEROUS_COMMANDS:
        if dangerous_cmd in command_lower:
            return True, f"Dangerous command detected: {dangerous_cmd}"

    # Check patterns
    for pattern in DANGEROUS_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return True, f"Dangerous command pattern detected: {pattern}"

    return False, None

def check_sensitive_path(path):
    """Check if a path accesses sensitive files or directories."""
    path_str = str(path).lower()

    # Check exact matches
    for sensitive_path in SENSITIVE_PATHS:
        if sensitive_path.replace('*', '') in path_str or path_str.startswith(sensitive_path.replace('/*', '')):
            return True, f"Access to sensitive path: {sensitive_path}"

    # Check patterns
    for pattern in SENSITIVE_PATH_PATTERNS:
        if re.search(pattern, path_str, re.IGNORECASE):
            return True, f"Access to sensitive path pattern: {pattern}"

    return False, None

def validate_tool_call(tool_data):
    """Validate a tool call for security issues."""
    tool_name = tool_data.get('tool')
    parameters = tool_data.get('parameters', {})

    if tool_name == 'Bash':
        command = parameters.get('command', '')
        is_dangerous, reason = check_dangerous_command(command)
        if is_dangerous:
            return False, f"Blocked dangerous Bash command: {reason}"

    elif tool_name in ['Read', 'Write', 'Edit', 'MultiEdit']:
        file_path = parameters.get('file_path', '')
        if file_path:
            is_sensitive, reason = check_sensitive_path(file_path)
            if is_sensitive:
                return False, f"Blocked access to sensitive file: {reason}"

    elif tool_name == 'Glob':
        pattern = parameters.get('pattern', '')
        path = parameters.get('path', '')

        for check_path in [pattern, path]:
            if check_path:
                is_sensitive, reason = check_sensitive_path(check_path)
                if is_sensitive:
                    return False, f"Blocked glob access to sensitive path: {reason}"

    elif tool_name == 'Grep':
        path = parameters.get('path', '')
        if path:
            is_sensitive, reason = check_sensitive_path(path)
            if is_sensitive:
                return False, f"Blocked grep access to sensitive path: {reason}"

    elif tool_name == 'LS':
        path = parameters.get('path', '')
        if path:
            is_sensitive, reason = check_sensitive_path(path)
            if is_sensitive:
                return False, f"Blocked directory listing of sensitive path: {reason}"

    return True, "Operation allowed"

def main():
    """Main hook function."""
    try:
        # Read input from stdin
        input_data = sys.stdin.read()

        # Parse JSON input
        tool_data = json.loads(input_data)

        # Validate the tool call
        is_safe, message = validate_tool_call(tool_data)

        if not is_safe:
            # Block the operation
            print(f"SECURITY BLOCK: {message}", file=sys.stderr)
            sys.exit(1)

        # Allow the operation
        sys.exit(0)

    except json.JSONDecodeError as e:
        print(f"Error parsing hook input: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Security hook error: {e}", file=sys.stderr)
        # In case of hook errors, allow operation to proceed (fail-open)
        sys.exit(0)

if __name__ == "__main__":
    main()
