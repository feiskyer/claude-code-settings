#!/bin/bash
#
# Autonomous Skill - Session Runner
# Executes Claude Code in headless mode with auto-continuation
#
# Supports two modes:
#   structured  - Full task decomposition with task_list.md (default)
#   lightweight - Same prompt repeated, Ralph-style iteration
#
# Usage:
#   ./run-session.sh "task description"
#   ./run-session.sh "fix tests" --lightweight
#   ./run-session.sh --task-name <name> --continue
#   ./run-session.sh --list
#

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────
AUTO_CONTINUE_DELAY=3
MAX_TURNS_INIT=50
MAX_TURNS_EXEC=100
DEFAULT_MODEL="sonnet"
DEFAULT_MAX_BUDGET="5.00"
DEFAULT_EFFORT="high"
DEFAULT_PERMISSION_MODE="bypassPermissions"
DEFAULT_COMPLETION_PROMISE="DONE"

# Resolve skill directory
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    SKILL_DIR="${CLAUDE_PLUGIN_ROOT}/skills/autonomous-skill"
else
    SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

AUTONOMOUS_DIR=".autonomous"

# Allow spawning claude -p from within an interactive Claude Code session.
# Without this, Claude Code refuses to launch nested sessions.
unset CLAUDECODE 2>/dev/null || true

# ── Colors ─────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

print_header()  { echo -e "\n${BLUE}══════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}══════════════════════════════════════════${NC}"; }
print_success() { echo -e "${GREEN}  [ok] $1${NC}"; }
print_warning() { echo -e "${YELLOW}  [!!] $1${NC}"; }
print_error()   { echo -e "${RED}  [err] $1${NC}"; }
print_info()    { echo -e "${CYAN}  [..] $1${NC}"; }

# ── Helpers ────────────────────────────────────────────────────────────

show_help() {
    cat <<'HELP'
Autonomous Skill - Session Runner

Usage:
  run-session.sh "task description"              Start new structured task
  run-session.sh "fix tests" --lightweight       Start lightweight (Ralph-style) task
  run-session.sh --task-name <n> --continue      Continue specific task
  run-session.sh --list                          List all tasks

Modes:
  --lightweight          Ralph-style: same prompt repeated, no task decomposition.
                         Best for iterative tasks (TDD, bug fixing, refactoring).
  (default)              Structured: full task decomposition with task_list.md.
                         Best for complex, multi-phase projects.

Options:
  --task-name <name>         Explicit task name
  --continue, -c             Continue existing task
  --completion-promise TEXT  Promise phrase to signal completion (default: DONE)
  --no-auto-continue         Single session only
  --max-sessions N           Limit total sessions (0 = unlimited)
  --max-budget N.NN          Per-session dollar budget (default: 5.00)
  --model <model>            Model alias or ID (default: sonnet)
  --fallback-model <m>       Fallback model if primary overloaded
  --effort <level>           Thinking effort: low|medium|high (default: high)
  --permission-mode <m>      Permission mode (default: bypassPermissions)
  --add-dir <dirs>           Extra directories to allow access
  --list, -l                 List all tasks with progress
  --help, -h                 Show this help

Completion:
  Sessions end when the agent outputs <promise>DONE</promise> (or your custom
  promise). In structured mode, completion also triggers when all task_list.md
  checkboxes are marked [x]. Use --completion-promise to change the phrase.
HELP
}

generate_task_name() {
    local desc="${1:-}"
    local result
    result=$(echo "$desc" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | cut -c1-30 | sed 's/^-//' | sed 's/-$//')
    if [ -z "$result" ]; then
        result="task-$(date +%Y%m%d-%H%M%S)"
        print_warning "Using generated name: $result"
    fi
    echo "$result"
}

validate_task_name() {
    local name="$1"
    if [[ "$name" == *".."* ]] || [[ "$name" == *"/"* ]] || [[ "$name" == *"\\"* ]]; then
        print_error "Invalid task name: '$name' (path traversal characters)"
        return 1
    fi
    if [ -z "$name" ]; then
        print_error "Task name cannot be empty"
        return 1
    fi
    if [[ "$name" == -* ]]; then
        print_error "Task name cannot start with a hyphen"
        return 1
    fi
    return 0
}

check_dependencies() {
    if ! command -v claude &> /dev/null; then
        print_error "'claude' CLI not found. Install: https://claude.ai/code"
        exit 1
    fi
}

# ── Lock file management ──────────────────────────────────────────────

acquire_lock() {
    local task_dir="$1"
    local lock_file="$task_dir/run.lock"
    if [ -f "$lock_file" ]; then
        local lock_pid
        lock_pid=$(cat "$lock_file" 2>/dev/null || echo "unknown")
        if kill -0 "$lock_pid" 2>/dev/null; then
            print_error "Task is already running (PID $lock_pid)"
            print_info "If this is stale, remove: $lock_file"
            return 1
        else
            print_warning "Stale lock found (PID $lock_pid not running). Removing."
            rm -f "$lock_file"
        fi
    fi
    echo $$ > "$lock_file"
    return 0
}

release_lock() {
    local task_dir="$1"
    rm -f "$task_dir/run.lock"
}

# ── Promise detection ─────────────────────────────────────────────────

check_promise_in_log() {
    local log_file="$1"
    local promise="$2"
    # Check for <promise>TEXT</promise> in the session log
    if grep -q "<promise>${promise}</promise>" "$log_file" 2>/dev/null; then
        return 0
    fi
    return 1
}

# ── Task listing ───────────────────────────────────────────────────────

list_tasks() {
    print_header "AUTONOMOUS TASKS"

    if [ ! -d "$AUTONOMOUS_DIR" ]; then
        print_warning "No tasks found ($AUTONOMOUS_DIR/ does not exist)"
        return
    fi

    local found=0
    for task_dir in "$AUTONOMOUS_DIR"/*/; do
        [ -d "$task_dir" ] || continue
        local task_name
        task_name=$(basename "$task_dir")
        local task_list="$task_dir/task_list.md"
        local mode_file="$task_dir/.mode"

        # Detect mode
        local mode="structured"
        [ -f "$mode_file" ] && mode=$(cat "$mode_file")

        if [ "$mode" == "lightweight" ]; then
            echo -e "  ${CYAN}lite${NC}  $task_name"
        elif [ -f "$task_list" ]; then
            local total done_count percent
            total=$(grep -c '^\- \[' "$task_list" 2>/dev/null || echo "0")
            done_count=$(grep -c '^\- \[x\]' "$task_list" 2>/dev/null || echo "0")
            percent=0
            [ "$total" -gt 0 ] && percent=$((done_count * 100 / total))

            if [ "$done_count" -eq "$total" ] && [ "$total" -gt 0 ]; then
                echo -e "  ${GREEN}done${NC}  $task_name  ($done_count/$total)"
            else
                echo -e "  ${YELLOW}${percent}%${NC}   $task_name  ($done_count/$total)"
            fi
        else
            echo -e "  ${RED}???${NC}   $task_name  (no task_list.md)"
        fi

        [ -f "$task_dir/run.lock" ] && echo -e "        ${DIM}(currently running)${NC}"
        found=$((found + 1))
    done

    [ "$found" -eq 0 ] && print_warning "No tasks found in $AUTONOMOUS_DIR/"
    echo ""
}

# ── Progress helpers ───────────────────────────────────────────────────

get_progress() {
    local task_dir="$1"
    if [ -f "$task_dir/task_list.md" ]; then
        local total done_count
        total=$(grep -c '^\- \[' "$task_dir/task_list.md" 2>/dev/null || echo "0")
        done_count=$(grep -c '^\- \[x\]' "$task_dir/task_list.md" 2>/dev/null || echo "0")
        echo "$done_count/$total"
    else
        echo "—"
    fi
}

is_complete() {
    local task_dir="$1"
    if [ -f "$task_dir/task_list.md" ]; then
        local total done_count
        total=$(grep -c '^\- \[' "$task_dir/task_list.md" 2>/dev/null || echo "0")
        done_count=$(grep -c '^\- \[x\]' "$task_dir/task_list.md" 2>/dev/null || echo "0")
        [ "$done_count" -eq "$total" ] && [ "$total" -gt 0 ]
    else
        return 1
    fi
}

task_exists() {
    [ -f "$AUTONOMOUS_DIR/$1/task_list.md" ]
}

# ── Session runners ────────────────────────────────────────────────────

build_claude_args() {
    local -a args=()
    args+=(--output-format stream-json --verbose)
    args+=(--model "$opt_model")
    args+=(--effort "$opt_effort")
    args+=(--max-budget-usd "$opt_max_budget")
    args+=(--permission-mode "$opt_permission_mode")
    args+=(--no-session-persistence)

    [ -n "$opt_fallback_model" ] && args+=(--fallback-model "$opt_fallback_model")
    [ -n "$opt_add_dir" ] && args+=(--add-dir "$opt_add_dir")

    echo "${args[@]}"
}

run_initializer() {
    local task_name="$1"
    local task_desc="$2"
    local task_dir="$AUTONOMOUS_DIR/$task_name"
    local session_num="$3"

    mkdir -p "$task_dir/sessions"

    local log_file="$task_dir/sessions/session-$(printf '%03d' "$session_num").log"

    print_info "Mode: Initializer"
    print_info "Task: $task_desc"
    print_info "Directory: $task_dir"
    print_info "Log: $log_file"

    local init_prompt
    init_prompt=$(sed "s|{TASK_DIR}|$task_dir|g" "$SKILL_DIR/templates/initializer-prompt.md")

    local claude_args
    claude_args=$(build_claude_args)

    local exit_code=0
    claude -p "Task: $task_desc
Task Name: $task_name
Task Directory: $task_dir
Completion Promise: $opt_completion_promise

$init_prompt" \
        $claude_args \
        --max-turns $MAX_TURNS_INIT \
        --append-system-prompt "You are the Initializer Agent. Create task_list.md and progress.md in $task_dir/. Project files go in their normal locations. When ALL work is genuinely complete, output <promise>$opt_completion_promise</promise>." \
        2>&1 | tee "$log_file" || exit_code=$?

    return $exit_code
}

run_executor() {
    local task_name="$1"
    local task_dir="$AUTONOMOUS_DIR/$task_name"
    local session_num="$2"

    local log_file="$task_dir/sessions/session-$(printf '%03d' "$session_num").log"

    print_info "Mode: Executor"
    print_info "Directory: $task_dir"
    print_info "Log: $log_file"

    local task_list progress_notes
    task_list=$(cat "$task_dir/task_list.md" 2>/dev/null || echo "No task list found")
    progress_notes=$(cat "$task_dir/progress.md" 2>/dev/null || echo "No progress notes yet")

    local exec_prompt
    exec_prompt=$(sed "s|{TASK_DIR}|$task_dir|g" "$SKILL_DIR/templates/executor-prompt.md")

    local claude_args
    claude_args=$(build_claude_args)

    local exit_code=0
    claude -p "Continue working on the task.
Task Name: $task_name
Task Directory: $task_dir
Completion Promise: $opt_completion_promise

Current task_list.md:
$task_list

Previous progress notes:
$progress_notes

$exec_prompt" \
        $claude_args \
        --max-turns $MAX_TURNS_EXEC \
        --append-system-prompt "You are the Executor Agent. Complete tasks and update files in $task_dir/. Project files go in their normal locations. When ALL tasks are genuinely complete, output <promise>$opt_completion_promise</promise>." \
        2>&1 | tee "$log_file" || exit_code=$?

    return $exit_code
}

run_lightweight() {
    local task_name="$1"
    local task_desc="$2"
    local task_dir="$AUTONOMOUS_DIR/$task_name"
    local session_num="$3"

    mkdir -p "$task_dir/sessions"

    local log_file="$task_dir/sessions/session-$(printf '%03d' "$session_num").log"

    print_info "Mode: Lightweight (iteration $session_num)"
    print_info "Log: $log_file"

    local claude_args
    claude_args=$(build_claude_args)

    local exit_code=0
    claude -p "$task_desc

---
You are in iteration $session_num of an iterative development loop.
Check existing files and git history to see your previous work.
Continue improving until the task is genuinely complete.

When the task is FULLY complete and verified, output exactly:
  <promise>$opt_completion_promise</promise>

Do NOT output the promise tag until everything is genuinely done and verified.
If tests exist, they must all pass. If builds exist, they must succeed.
Keep iterating until quality is right." \
        $claude_args \
        --max-turns $MAX_TURNS_EXEC \
        --append-system-prompt "You are in a lightweight autonomous loop (iteration $session_num). Work on the task, check your previous work in files/git. Output <promise>$opt_completion_promise</promise> ONLY when genuinely complete." \
        2>&1 | tee "$log_file" || exit_code=$?

    return $exit_code
}

# ── Main ───────────────────────────────────────────────────────────────

main() {
    local task_desc=""
    local task_name=""
    local auto_continue=true
    local max_sessions=0
    local continue_mode=false
    local opt_model="$DEFAULT_MODEL"
    local opt_fallback_model=""
    local opt_max_budget="$DEFAULT_MAX_BUDGET"
    local opt_effort="$DEFAULT_EFFORT"
    local opt_permission_mode="$DEFAULT_PERMISSION_MODE"
    local opt_completion_promise="$DEFAULT_COMPLETION_PROMISE"
    local opt_add_dir=""
    local opt_lightweight=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)       show_help; exit 0 ;;
            --list|-l)       list_tasks; exit 0 ;;
            --task-name|-n)  task_name="${2:-}"; shift 2 ;;
            --continue|-c)   continue_mode=true; shift ;;
            --no-auto-continue) auto_continue=false; shift ;;
            --max-sessions)  max_sessions="${2:-0}"; shift 2 ;;
            --max-budget)    opt_max_budget="${2:-$DEFAULT_MAX_BUDGET}"; shift 2 ;;
            --model)         opt_model="${2:-$DEFAULT_MODEL}"; shift 2 ;;
            --fallback-model) opt_fallback_model="${2:-}"; shift 2 ;;
            --effort)        opt_effort="${2:-$DEFAULT_EFFORT}"; shift 2 ;;
            --permission-mode) opt_permission_mode="${2:-$DEFAULT_PERMISSION_MODE}"; shift 2 ;;
            --completion-promise) opt_completion_promise="${2:-$DEFAULT_COMPLETION_PROMISE}"; shift 2 ;;
            --add-dir)       opt_add_dir="${2:-}"; shift 2 ;;
            --lightweight)   opt_lightweight=true; shift ;;
            *)               task_desc="$1"; shift ;;
        esac
    done

    # Determine task name
    if [ -z "$task_name" ] && [ -n "$task_desc" ]; then
        task_name=$(generate_task_name "$task_desc")
        print_info "Generated task name: $task_name"
    fi

    # Handle --continue without explicit name
    if [ -z "$task_name" ]; then
        if [ "$continue_mode" = true ]; then
            if [ -d "$AUTONOMOUS_DIR" ]; then
                task_name=$(ls -t "$AUTONOMOUS_DIR" 2>/dev/null | head -1) || true
            fi
            if [ -z "$task_name" ]; then
                print_error "No task name provided and no existing tasks found"
                exit 1
            fi
            print_info "Continuing most recent task: $task_name"
        else
            print_error "No task description or name provided"
            show_help
            exit 1
        fi
    fi

    validate_task_name "$task_name" || exit 1
    check_dependencies

    local task_dir="$AUTONOMOUS_DIR/$task_name"
    mkdir -p "$task_dir/sessions"

    # Save mode marker for --list display
    if [ "$opt_lightweight" = true ]; then
        echo "lightweight" > "$task_dir/.mode"
    elif [ ! -f "$task_dir/.mode" ]; then
        echo "structured" > "$task_dir/.mode"
    fi

    # Detect mode from existing task if continuing
    if [ "$continue_mode" = true ] && [ -f "$task_dir/.mode" ]; then
        local saved_mode
        saved_mode=$(cat "$task_dir/.mode")
        if [ "$saved_mode" == "lightweight" ]; then
            opt_lightweight=true
        fi
    fi

    # Acquire lock
    if ! acquire_lock "$task_dir"; then
        exit 1
    fi
    trap 'release_lock "$task_dir"; echo ""; print_warning "Progress saved in $task_dir/"; echo "  Resume: $0 --task-name $task_name --continue"' EXIT

    print_info "Completion promise: <promise>$opt_completion_promise</promise>"
    if [ "$opt_lightweight" = true ]; then
        print_info "Mode: lightweight (Ralph-style iteration)"
    else
        print_info "Mode: structured (task decomposition)"
    fi

    local session_num=1
    local retry_count=0
    local max_retries=1

    # ── Session loop ───────────────────────────────────────────────────
    while true; do
        print_header "SESSION $session_num  [$task_name]"

        if [ "$opt_lightweight" = false ] && task_exists "$task_name"; then
            print_info "Progress: $(get_progress "$task_dir")"
        fi

        # Run the appropriate agent
        local exit_code=0
        local log_file="$task_dir/sessions/session-$(printf '%03d' "$session_num").log"

        if [ "$opt_lightweight" = true ]; then
            # Lightweight mode: same prompt, no task decomposition
            run_lightweight "$task_name" "$task_desc" "$session_num" || exit_code=$?
        elif task_exists "$task_name"; then
            run_executor "$task_name" "$session_num" || exit_code=$?
        else
            if [ -z "$task_desc" ]; then
                print_error "Task '$task_name' not found and no description provided"
                exit 1
            fi
            run_initializer "$task_name" "$task_desc" "$session_num" || exit_code=$?
        fi

        # Handle session failure
        if [ $exit_code -ne 0 ]; then
            print_error "Session exited with code $exit_code"
            if [ $retry_count -lt $max_retries ]; then
                retry_count=$((retry_count + 1))
                print_warning "Retrying (attempt $retry_count/$max_retries)..."
                sleep 2
                continue
            else
                print_error "Max retries reached. Stopping."
                exit 1
            fi
        fi
        retry_count=0

        # ── Check completion (promise OR checkboxes) ───────────────────
        echo ""

        # 1. Check promise-based completion
        if [ -f "$log_file" ] && check_promise_in_log "$log_file" "$opt_completion_promise"; then
            print_header "PROMISE FULFILLED: <promise>$opt_completion_promise</promise>"
            print_success "Task '$task_name' completed in $session_num session(s)"
            print_info "Results in: $task_dir/"
            exit 0
        fi

        # 2. Check task-list completion (structured mode only)
        if [ "$opt_lightweight" = false ]; then
            print_info "Progress after session $session_num: $(get_progress "$task_dir")"
            if is_complete "$task_dir"; then
                print_header "ALL TASKS COMPLETED"
                print_success "Task '$task_name' finished in $session_num session(s)"
                print_info "Results in: $task_dir/"
                exit 0
            fi
        else
            print_info "Lightweight iteration $session_num complete (no promise detected)"
        fi

        # Check max sessions
        if [ $max_sessions -gt 0 ] && [ $session_num -ge $max_sessions ]; then
            print_warning "Reached session limit ($max_sessions)"
            print_info "Resume later: $0 --task-name $task_name --continue"
            exit 0
        fi

        # Auto-continue
        if [ "$auto_continue" = true ]; then
            echo ""
            print_info "Next session in ${AUTO_CONTINUE_DELAY}s... (Ctrl+C to stop)"
            sleep $AUTO_CONTINUE_DELAY
        else
            print_info "Auto-continue disabled."
            exit 0
        fi

        session_num=$((session_num + 1))
    done
}

main "$@"
