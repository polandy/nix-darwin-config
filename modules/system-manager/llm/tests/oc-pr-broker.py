"""Build-time test for oc-pr-broker and the oc-pr client: a local bare repo stands in for GitHub,
a fake gh answers from a scenario. Usage: python3 oc-pr-broker.py <oc-pr-broker> <oc-pr>"""
import json
import os
import socket
import subprocess
import sys
import tempfile

BROKER, CLIENT = map(os.path.abspath, sys.argv[1:3])
os.environ.update(GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1")
TMP = tempfile.mkdtemp()
BIN = os.path.join(TMP, "bin")
FAKE_GIT_BIN = os.path.join(TMP, "fake-git-bin")
GH_LOG = os.path.join(TMP, "gh.log")
GIT_LOG = os.path.join(TMP, "git.log")
SCENARIO = os.path.join(TMP, "scenario.json")
REMOTE = os.path.join(TMP, "remote.git")
WORK = os.path.join(TMP, "work")
SOCK = os.path.join(TMP, "pr.sock")
OID = "a" * 40
failures = []

FAKE_GH = f"""#!{sys.executable}
import json, sys
args = sys.argv[1:]
stdin = sys.stdin.read() if "--body-file" in args else ""
with open({GH_LOG!r}, "a") as f:
    f.write(json.dumps({{"args": args, "stdin": stdin}}) + "\\n")
r = json.load(open({SCENARIO!r})).get(" ".join(args[:2]), {{"out": "", "rc": 1}})
print(r["out"])
sys.exit(r.get("rc", 0))
"""
FAKE_GIT = f"""#!/bin/sh
echo "$*" >> {GIT_LOG}
exit 1
"""


def write(path, text, mode=0o755):
    with open(path, "w") as f:
        f.write(text)
    os.chmod(path, mode)


def sh(*cmd, cwd=WORK):
    return subprocess.run(cmd, cwd=cwd, check=True, capture_output=True, text=True).stdout.strip()


def setup():
    os.makedirs(BIN)
    os.makedirs(FAKE_GIT_BIN)
    write(os.path.join(BIN, "gh"), FAKE_GH)
    write(os.path.join(FAKE_GIT_BIN, "gh"), FAKE_GH)
    write(os.path.join(FAKE_GIT_BIN, "git"), FAKE_GIT)
    os.makedirs(os.path.join(TMP, "creds"))
    write(os.path.join(TMP, "creds", "github-token"), "test-token\n", 0o600)
    sh("git", "init", "-q", "--bare", "-b", "main", REMOTE, cwd=TMP)
    sh("git", "clone", "-q", REMOTE, WORK, cwd=TMP)
    for k, v in (("user.name", "t"), ("user.email", "t@localhost"), ("commit.gpgsign", "false")):
        sh("git", "config", k, v)
    sh("git", "commit", "-q", "--allow-empty", "-m", "init")
    sh("git", "push", "-q", "origin", "main")
    sh("git", "remote", "remove", "origin")
    sh("git", "switch", "-q", "-c", "feat/x")
    sh("git", "commit", "-q", "--allow-empty", "-m", "feat: first", "-m", "Body of first.")


def scenario(**over):
    s = {"repo view": {"out": "main"}, "pr list": {"out": ""},
         "pr create": {"out": "https://github.com/polandy/r/pull/7"}, "pr merge": {"out": ""}}
    s.update(over)
    with open(SCENARIO, "w") as f:
        json.dump(s, f)
    for log in (GH_LOG, GIT_LOG):
        if os.path.exists(log):
            os.remove(log)


def calls(log):
    if not os.path.exists(log):
        return []
    with open(log) as f:
        return [json.loads(line) if log == GH_LOG else line for line in f]


def broker_env(fake_git):
    return {"PATH": (FAKE_GIT_BIN if fake_git else BIN) + ":" + os.environ["PATH"],
            "STATE_DIRECTORY": os.path.join(TMP, "state"), "CREDENTIALS_DIRECTORY": os.path.join(TMP, "creds"),
            "OC_PR_REMOTE": REMOTE, "OC_PR_REVIEWERS": "polandy"}


def serve(fake_git):
    """Accept one connection like systemd (Accept=yes) and run the broker on it."""
    srv.settimeout(30)
    conn, _ = srv.accept()
    p = subprocess.Popen([sys.executable, BROKER, "polandy/r"], stdin=conn, stdout=conn,
                         stderr=subprocess.PIPE, env=broker_env(fake_git), text=True)
    conn.close()
    return p


def client(*args, fake_git=False):
    c = subprocess.Popen([sys.executable, CLIENT, *args], cwd=WORK, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                         text=True, env={**os.environ, "OC_PR_SOCKET": SOCK})
    try:
        b = serve(fake_git)
    except TimeoutError:
        raise SystemExit(f"client {args} never connected: {c.communicate()[0]}")
    out = c.communicate(timeout=60)[0]
    log = b.communicate(timeout=60)[1]
    return c.returncode, out.strip(), log


def raw(lines, fake_git=False, bundle=None):
    """Talk to the broker directly (requests the client never sends)."""
    with socket.socket(socket.AF_UNIX) as s:
        s.connect(SOCK)
        b = serve(fake_git)
        s.sendall(lines)
        r = s.makefile("rb")
        resp = json.loads(r.readline())
        if bundle is not None and "have" in resp:
            s.sendall(f"{len(bundle)}\n".encode() + bundle)
            resp = json.loads(r.readline())
    b.communicate(timeout=60)
    return resp


def check(name, cond, detail=""):
    if not cond:
        failures.append(f"FAIL {name}: {detail}")
        print(failures[-1], flush=True)


def remote_sha(ref):
    return subprocess.run(["git", "-C", REMOTE, "rev-parse", "-q", "--verify", ref],
                          capture_output=True, text=True).stdout.strip()


def gh_did(verb):
    return [c for c in calls(GH_LOG) if c["args"][:2] == verb.split()]


setup()
srv = socket.socket(socket.AF_UNIX)
srv.bind(SOCK)
srv.listen(4)

# Refused before git or the network is touched (fake git logs and fails).
for branch in ("main", "master", "HEAD", "-f", "a..b", "x.lock", "refs/../main", "feat/.x", ""):
    scenario()
    resp = raw(json.dumps({"verb": "push", "branch": branch}).encode() + b"\n", fake_git=True)
    check(f"push {branch!r} refused", not resp["ok"], resp)
    check(f"push {branch!r} runs no git", calls(GIT_LOG) == [], calls(GIT_LOG))
scenario(**{"repo view": {"out": "trunk"}})
resp = raw(b'{"verb": "push", "branch": "trunk"}\n', fake_git=True)
check("push default branch refused", not resp["ok"] and "protected" in resp["message"], resp)
for req in (b'{"verb": "delete-branch", "branch": "feat/x"}\n', b'{"verb": "gh", "args": ["repo", "delete"]}\n',
            b'{"verb": "push --force"}\n', b"not json\n", b"[1]\n", b"\n"):
    scenario()
    resp = raw(req, fake_git=True)
    check(f"{req!r} refused", not resp["ok"] and "unknown verb" in resp["message"], resp)
    check(f"{req!r} calls nothing", calls(GIT_LOG) == [] and calls(GH_LOG) == [], (calls(GIT_LOG), calls(GH_LOG)))

# Client-side usage errors never reach the broker.
for args in (("merge", "abc"), ("frobnicate",), ("push", "a", "b"), ("pr-create", "--draft", "x")):
    p = subprocess.run([sys.executable, CLIENT, *args], cwd=WORK, capture_output=True, text=True,
                       env={**os.environ, "OC_PR_SOCKET": os.path.join(TMP, "none.sock")})
    check(f"client {args} usage", p.returncode != 0 and "not reachable" not in p.stderr, p.stderr)

# pr-create before the branch is pushed.
scenario()
rc, out, _ = client("pr-create")
check("pr-create unpushed refused", rc == 1 and "not pushed" in out, out)
check("pr-create unpushed creates nothing", gh_did("pr create") == [], calls(GH_LOG))

# Push the feature branch (current branch), then again (up to date).
scenario()
rc, out, log = client("push")
tip = sh("git", "rev-parse", "feat/x")
check("push ok", rc == 0 and out.startswith("pushed feat/x"), out + log)
check("push reached remote", remote_sha("refs/heads/feat/x") == tip, remote_sha("refs/heads/feat/x"))
check("push logged", "ok: pushed feat/x" in log, log)
check("push records time", os.path.exists(os.path.join(TMP, "state", "r", "pushed", tip)))
check("token not logged", "test-token" not in log, log)
scenario()
rc, out, _ = client("push", "feat/x")
check("push again up to date", rc == 0 and out == "up to date", out)

# Second commit: incremental bundle against the remote branch.
sh("git", "commit", "-q", "--allow-empty", "-m", "feat: second")
scenario()
rc, out, _ = client("push")
check("push fast-forward ok", rc == 0 and remote_sha("refs/heads/feat/x") == sh("git", "rev-parse", "feat/x"), out)

# Rewritten history is no fast-forward: refused, remote unchanged.
before = remote_sha("refs/heads/feat/x")
sh("git", "commit", "-q", "--amend", "--allow-empty", "-m", "feat: rewritten")
scenario()
rc, out, log = client("push")
check("force push refused", rc == 1 and "not a fast-forward" in out, out)
check("force push remote unchanged", remote_sha("refs/heads/feat/x") == before)
check("force push logged", "refused: not a fast-forward" in log, log)
sh("git", "reset", "-q", "--hard", before)

# A bundle with a tag, or naming another branch than requested, is refused.
sh("git", "commit", "-q", "--allow-empty", "-m", "feat: third")
sh("git", "tag", "v1")
tagged = subprocess.run(["git", "bundle", "create", "-q", "-", "refs/heads/feat/x", "refs/tags/v1", f"^{before}"],
                        cwd=WORK, capture_output=True, check=True).stdout
scenario()
resp = raw(b'{"verb": "push", "branch": "feat/x"}\n', bundle=tagged)
check("bundle with tag refused", not resp["ok"] and "exactly the branch" in resp["message"], resp)
check("tag not pushed", remote_sha("refs/tags/v1") == "")
sh("git", "branch", "-q", "main-copy", "feat/x")
other = subprocess.run(["git", "bundle", "create", "-q", "-", "refs/heads/main-copy", f"^{before}"],
                       cwd=WORK, capture_output=True, check=True).stdout
scenario()
resp = raw(b'{"verb": "push", "branch": "feat/x"}\n', bundle=other)
check("bundle of another branch refused", not resp["ok"], resp)
check("feat/x unchanged after refused bundles", remote_sha("refs/heads/feat/x") == before)

# pr-create: title and body from the commits, base is the default branch.
scenario()
rc, out, _ = client("pr-create")
created = gh_did("pr create")
check("pr-create ok", rc == 0 and out == "created https://github.com/polandy/r/pull/7", out)
if created:
    a = created[0]["args"]
    check("pr-create args", a[a.index("--base") + 1] == "main" and a[a.index("--head") + 1] == "feat/x"
          and a[a.index("--title") + 1] == "feat: first" and a[-2:] == ["-R", "polandy/r"], a)
    check("pr-create body", created[0]["stdin"] == "- feat: first\n- feat: second", created[0]["stdin"])
scenario(**{"pr list": {"out": "https://github.com/polandy/r/pull/7"}})
rc, out, _ = client("pr-create", "--title", "x")
check("pr-create existing", rc == 0 and out.startswith("exists") and gh_did("pr create") == [], out)
scenario()
rc, out, _ = client("pr-create", "--title", "a\nb")
check("pr-create multi-line title refused", rc == 1 and "invalid title" in out, out)

# merge: green gate, then every red or pending reason refuses without merging.
REVIEW = {"id": "IC_1", "author": {"login": "polandy"},
          "body": "## PR quality review\n\n### Merge readiness\nReady to merge."}


def view(**over):
    v = {"state": "OPEN", "isDraft": False, "mergeable": "MERGEABLE", "title": "t", "comments": [REVIEW],
         "commits": [{"committedDate": "2026-01-01T00:00:00Z"}], "headRefName": "feat/y", "headRefOid": OID,
         "baseRefName": "main", "isCrossRepository": False}
    v.update(over)
    return {"out": json.dumps(v)}


GREEN = {"pr view": view(), "pr checks": {"out": json.dumps([{"name": "eval", "bucket": "pass"}])},
         "api graphql": {"out": "2026-01-02T00:00:00Z"}}
scenario(**GREEN)
rc, out, _ = client("merge", "#12")
merged = gh_did("pr merge")
check("merge green ok", rc == 0 and out == "merged #12", out)
check("merge args", merged and merged[0]["args"] == ["pr", "merge", "12", "--squash", "--delete-branch",
                                                      "--match-head-commit", OID, "-R", "polandy/r"], merged)

reds = {
    "checks pending": {"pr checks": {"out": json.dumps([{"name": "eval", "bucket": "pending"}]), "rc": 8}},
    "checks failing": {"pr checks": {"out": json.dumps([{"name": "eval", "bucket": "fail"}]), "rc": 1}},
    "no checks": {"pr checks": {"out": "no checks reported", "rc": 1}},
    "no review": {"pr view": view(comments=[])},
    "review not ready": {"pr view": view(comments=[{**REVIEW, "body": "PR quality review\nMerge readiness: not ready"}])},
    "review no verdict": {"pr view": view(comments=[{**REVIEW, "body": "PR quality review\nlooks fine"}])},
    "review by stranger": {"pr view": view(comments=[{**REVIEW, "author": {"login": "mallory"}}])},
    "stale review after newer comment": {"pr view": view(comments=[REVIEW, {**REVIEW, "id": "IC_2", "body": "PR quality review\nMerge readiness: NOT READY"}])},
    "review older than head": {"api graphql": {"out": "2025-12-31T00:00:00Z"}},
    "closed": {"pr view": view(state="MERGED")},
    "draft": {"pr view": view(isDraft=True)},
    "fork": {"pr view": view(isCrossRepository=True)},
    "head main": {"pr view": view(headRefName="main")},
    "base not default": {"pr view": view(baseRefName="release")},
    "conflicting": {"pr view": view(mergeable="CONFLICTING")},
    "mergeable unknown": {"pr view": view(mergeable="UNKNOWN")},
}
for name, over in reds.items():
    scenario(**{**GREEN, **over})
    rc, out, log = client("merge", "12")
    check(f"merge {name} refused", rc == 1 and out.startswith("refused: gate"), out)
    check(f"merge {name} not merged", gh_did("pr merge") == [], calls(GH_LOG))
    check(f"merge {name} logged", "refused: gate" in log, log)

# The commit date is the agent's: a review older than the broker's own push of the head is stale.
pushed = remote_sha("refs/heads/feat/x")
scenario(**{**GREEN, "pr view": view(headRefOid=pushed, commits=[{"committedDate": "2000-01-01T00:00:00Z"}]),
            "api graphql": {"out": "2001-01-01T00:00:00Z"}})
rc, out, _ = client("merge", "12")
check("merge review older than push refused", rc == 1 and "older than head" in out and gh_did("pr merge") == [], out)
for bad in (b'{"verb": "merge", "pr": "12; rm"}\n', b'{"verb": "merge", "pr": true}\n', b'{"verb": "merge", "pr": -1}\n'):
    scenario(**GREEN)
    resp = raw(bad, fake_git=True)
    check(f"merge {bad!r} refused", not resp["ok"] and gh_did("pr merge") == [], resp)

srv.close()
print(f"oc-pr-broker: {len(failures)} failed" if failures else "oc-pr-broker: all cases pass")
sys.exit(1 if failures else 0)
