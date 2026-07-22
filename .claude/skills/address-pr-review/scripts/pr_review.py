#!/usr/bin/env -S uv run --frozen python
"""
pr_review.py - state-aware GitHub PR review thread management.

Companion script for the /address-pr-review skill. Handles Copilot review
lifecycle: detect current state, trigger reviews, wait for completion, and
resolve threads via GraphQL.

Review states
-------------
A = no fresh Copilot review exists, none requested  -> trigger + wait
B = no fresh Copilot review exists, one is queued   -> wait
C = fresh Copilot review exists, unresolved threads -> process them
D = fresh Copilot review exists, no unresolved      -> DONE (only clean-exit)

"Fresh" means a review whose commit SHA matches the PR's current HEAD SHA.
"In progress" means Copilot is in the PR's requested_reviewers list.

Subcommands
-----------
state --pr N
    Detect the current state. Prints JSON; exit code = state-specific:
      0 = D (clean), 1 = C (unresolved), 2 = B (in progress), 3 = A (none).

trigger --pr N
    Request Copilot review (gh pr edit --add-reviewer). Idempotent.

wait --pr N [--interval 30] [--timeout 480]
    Poll until state resolves to C or D. Same JSON shape as `state`.
    Exit 1 = C, 0 = D, 4 = timeout.

resolve <thread-id>
    Resolve a single review thread via GraphQL.

# :example
.claude/skills/address-pr-review/scripts/pr_review.py state --pr 37
.claude/skills/address-pr-review/scripts/pr_review.py trigger --pr 37
.claude/skills/address-pr-review/scripts/pr_review.py wait --pr 37 --timeout 480
.claude/skills/address-pr-review/scripts/pr_review.py resolve PRRT_xxx
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time

COPILOT_REVIEWER_LOGIN = "copilot-pull-request-reviewer"  # author of submitted reviews
# The requested_reviewers users list may surface Copilot under either login
# depending on the API surface: "Copilot" (bot display login) or the same
# "copilot-pull-request-reviewer" slug used when triggering. Accept both so
# state detection doesn't misclassify an in-progress review as "not requested"
# and re-trigger in a loop.
COPILOT_REQUESTED_LOGINS = frozenset({"Copilot", COPILOT_REVIEWER_LOGIN})

STATE_QUERY = """
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      headRefOid
      reviews(last: 50) {
        nodes {
          author { login }
          submittedAt
          commit { oid }
        }
      }
    }
  }
}
"""

THREADS_PAGE_QUERY = """
query($owner: String!, $repo: String!, $pr: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { endCursor hasNextPage }
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 1) {
            nodes {
              body
              path
              line
              originalLine
              author { login }
            }
          }
        }
      }
    }
  }
}
"""

RESOLVE_MUTATION = """
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { isResolved }
  }
}
"""


def _run_gh(cmd: list[str]) -> str:
    """
    Run a gh command, returning stdout. Exit with a concise message on failure.

    Using check=True here would raise CalledProcessError and dump a Python
    traceback on common, expected failures (gh not installed, not logged in,
    missing scopes). Surface a readable one-line error the calling skill can
    show the user instead.
    """
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
    except FileNotFoundError:
        print("gh CLI not found on PATH. Install and authenticate gh.", file=sys.stderr)
        raise SystemExit(1) from None
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "unknown error"
        print(f"gh command failed ({' '.join(cmd[:3])} ...): {detail}", file=sys.stderr)
        raise SystemExit(1)
    return result.stdout


def _repo_info() -> tuple[str, str]:
    """Return (owner, repo_name) from gh."""
    data = json.loads(_run_gh(["gh", "repo", "view", "--json", "owner,name"]))
    return data["owner"]["login"], data["name"]


def _auto_pr() -> int:
    """Auto-detect PR number from current branch."""
    try:
        result = subprocess.run(
            ["gh", "pr", "view", "--json", "number", "--jq", ".number"],
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        print("gh CLI not found on PATH. Install and authenticate gh.", file=sys.stderr)
        raise SystemExit(1) from None
    if result.returncode != 0 or not result.stdout.strip():
        print("No open PR on this branch. Push first or specify --pr.", file=sys.stderr)
        raise SystemExit(1)
    return int(result.stdout.strip())


def _graphql(query: str, **variables: str | int) -> dict:
    """Run a GraphQL query via gh api."""
    cmd = ["gh", "api", "graphql", "-f", f"query={query}"]
    for k, v in variables.items():
        flag = "-F" if isinstance(v, int) else "-f"
        cmd.extend([flag, f"{k}={v}"])
    return json.loads(_run_gh(cmd))


def _copilot_requested(owner: str, repo: str, pr: int) -> bool:
    """Check if Copilot is in the PR's requested_reviewers list."""
    data = json.loads(
        _run_gh(["gh", "api", f"repos/{owner}/{repo}/pulls/{pr}/requested_reviewers"])
    )
    return any(
        u.get("login") in COPILOT_REQUESTED_LOGINS for u in data.get("users", [])
    )


def _flatten_thread(thread: dict) -> dict:
    """Flatten a thread node into a simple dict for Claude to consume."""
    comments = thread["comments"]["nodes"]
    first = comments[0] if comments else {}
    return {
        "id": thread["id"],
        "isOutdated": thread["isOutdated"],
        "path": first.get("path", ""),
        "line": first.get("line") or first.get("originalLine"),
        "author": (first.get("author") or {}).get("login", "unknown"),
        "body": first.get("body", ""),
    }


def _fetch_all_threads(owner: str, repo: str, pr: int) -> list[dict]:
    """Fetch all review threads via cursor pagination (no first:N cap)."""
    all_threads: list[dict] = []
    cursor: str | None = None
    while True:
        kwargs: dict[str, str | int] = {"owner": owner, "repo": repo, "pr": pr}
        if cursor is not None:
            kwargs["cursor"] = cursor
        data = _graphql(THREADS_PAGE_QUERY, **kwargs)
        block = data["data"]["repository"]["pullRequest"]["reviewThreads"]
        all_threads.extend(block["nodes"])
        if not block["pageInfo"]["hasNextPage"]:
            break
        cursor = block["pageInfo"]["endCursor"]
    return all_threads


def _detect_state(owner: str, repo: str, pr: int) -> dict:
    """Run state detection. Returns a dict for JSON output + exit-code decisions."""
    data = _graphql(STATE_QUERY, owner=owner, repo=repo, pr=pr)
    pr_node = (data.get("data") or {}).get("repository", {}).get("pullRequest")
    if pr_node is None:
        print(
            f"PR #{pr} not found in {owner}/{repo} (invalid number or no access).",
            file=sys.stderr,
        )
        raise SystemExit(1)
    head_sha = pr_node["headRefOid"]

    # Find the most-recent Copilot review matching HEAD SHA. GraphQL can return
    # author: null (deleted user) or commit: null (edge cases), so guard both
    # rather than indexing blindly.
    copilot_reviews = [
        r
        for r in pr_node["reviews"]["nodes"]
        if (r.get("author") or {}).get("login") == COPILOT_REVIEWER_LOGIN
    ]
    copilot_reviews.sort(key=lambda r: r.get("submittedAt") or "", reverse=True)
    fresh_review = next(
        (r for r in copilot_reviews if (r.get("commit") or {}).get("oid") == head_sha),
        None,
    )
    fresh_review_sha = (
        (fresh_review.get("commit") or {}).get("oid") if fresh_review else None
    )

    # Only fetch review threads when a fresh review exists (states C/D). Without
    # one (states A/B), the threads are irrelevant to classification, so skip the
    # paginated fetch - it would add unnecessary GitHub API calls to every `wait`
    # poll and risk rate limits.
    fresh_threads: list[dict] = []
    if fresh_review_sha is not None:
        all_threads = _fetch_all_threads(owner, repo, pr)
        fresh_threads = [
            _flatten_thread(t)
            for t in all_threads
            if not t["isResolved"] and not t["isOutdated"]
        ]
        state = "C" if fresh_threads else "D"
        # A fresh review exists, so state is C/D regardless of this flag. Report the
        # real requested-reviewer status rather than assuming True, so the field
        # stays semantically accurate for callers.
        copilot_requested = _copilot_requested(owner, repo, pr)
    else:
        copilot_requested = _copilot_requested(owner, repo, pr)
        state = "B" if copilot_requested else "A"

    return {
        "state": state,
        "headSha": head_sha,
        "freshReviewSha": fresh_review_sha,
        "copilotRequested": copilot_requested,
        "unresolvedFreshThreads": fresh_threads,
    }


def _state_exit_code(state: str) -> int:
    """Map state letter to exit code (D=0, C=1, B=2, A=3)."""
    return {"D": 0, "C": 1, "B": 2, "A": 3}[state]


def cmd_state(args: argparse.Namespace) -> int:
    """Detect and print current review state."""
    pr = args.pr or _auto_pr()
    owner, repo = _repo_info()
    result = _detect_state(owner, repo, pr)
    json.dump(result, sys.stdout, indent=2)
    print()
    return _state_exit_code(result["state"])


def cmd_trigger(args: argparse.Namespace) -> int:
    """Request Copilot review (idempotent)."""
    pr = args.pr or _auto_pr()
    # route through _run_gh for consistent, traceback-free errors (missing gh,
    # auth failure, etc.) - it exits with a concise message on failure
    _run_gh(["gh", "pr", "edit", str(pr), "--add-reviewer", COPILOT_REVIEWER_LOGIN])
    print(json.dumps({"triggered": True, "pr": pr}))
    return 0


def cmd_wait(args: argparse.Namespace) -> int:
    """Poll until state resolves to C or D, or timeout."""
    pr = args.pr or _auto_pr()
    owner, repo = _repo_info()
    deadline = time.monotonic() + args.timeout
    attempt = 0

    while time.monotonic() < deadline:
        attempt += 1
        result = _detect_state(owner, repo, pr)

        if result["state"] in ("C", "D"):
            json.dump(result, sys.stdout, indent=2)
            print()
            return _state_exit_code(result["state"])

        remaining = int(deadline - time.monotonic())
        print(
            f"Poll #{attempt}: state={result['state']} "
            f"(requested={result['copilotRequested']}, {remaining}s remaining)...",
            file=sys.stderr,
        )
        time.sleep(args.interval)

    # Timeout: emit the last-known state and exit 4.
    final = _detect_state(owner, repo, pr)
    json.dump(final, sys.stdout, indent=2)
    print()
    return 4


def cmd_resolve(args: argparse.Namespace) -> int:
    """Resolve a single thread."""
    data = _graphql(RESOLVE_MUTATION, threadId=args.thread_id)
    resolved = data["data"]["resolveReviewThread"]["thread"]["isResolved"]
    json.dump({"resolved": resolved}, sys.stdout)
    print()
    return 0 if resolved else 1


def main(argv: list[str]) -> int:
    """Parse args, dispatch to state/trigger/wait/resolve."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[1])
    sub = parser.add_subparsers(dest="command", required=True)

    p_state = sub.add_parser("state", help="Detect current review state")
    p_state.add_argument("--pr", type=int, help="PR number (auto-detect if omitted)")

    p_trigger = sub.add_parser("trigger", help="Request Copilot review")
    p_trigger.add_argument("--pr", type=int, help="PR number (auto-detect if omitted)")

    p_wait = sub.add_parser("wait", help="Poll until state resolves to C or D")
    p_wait.add_argument("--pr", type=int, help="PR number (auto-detect if omitted)")
    p_wait.add_argument(
        "--interval", type=int, default=30, help="Seconds between polls"
    )
    p_wait.add_argument(
        "--timeout", type=int, default=480, help="Total timeout in seconds"
    )

    p_resolve = sub.add_parser("resolve", help="Resolve a review thread")
    p_resolve.add_argument("thread_id", help="GraphQL node ID (PRRT_*)")

    args = parser.parse_args(argv)
    handlers = {
        "state": cmd_state,
        "trigger": cmd_trigger,
        "wait": cmd_wait,
        "resolve": cmd_resolve,
    }
    return handlers[args.command](args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
