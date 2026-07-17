# OWNER PASS — read fresh, act once, record, hand back

You are running one pass of the owner loop for <project>. A harness re-runs
you with fresh context until the work is verifiably done — everything you need
is on disk, nothing is in your memory. Do exactly one item this pass.

1. Read, in order: SPEC.md, RESEARCH.md, BACKLOG.md, LOOP-STATE.md; skim
   recent `git log --oneline -15`.
2. Re-align: does the top in-scope item still serve SPEC.md's intent given
   LOOP-STATE.md? If drift, fix the backlog first (record why) instead of
   executing.
3. Take the single top unfinished in-scope item. If its done_when is not
   mechanical, tighten it (goal discipline) before touching code — never
   execute a wish.
4. Execute with loop discipline: smallest credible change, on a claude/ branch
   or worktree, git checkpoint before anything consequential.
5. Verify: run the item's stated check(s) and paste the REAL output. UI work
   needs end-to-end proof, not edit-success. If a gated action is required
   (deploy, send, delete, prod, spend, schema/access), PREPARE it, write
   NEEDS-APPROVAL to LOOP-STATE.md, and end the pass.
6. Record in LOOP-STATE.md: what changed, evidence, assumptions made, item
   status; update BACKLOG.md (status + re-score if new info). Commit with a
   human-readable message.
7. Hand back:
   - Unfinished checkable items remain, no cap/gate hit → end the pass
     normally; the harness re-prompts you.
   - Every in-scope item verified done → print exactly:
     <promise>OWNER-DONE</promise> followed by the evidence list.
   - Blocked/stalled → write BLOCKED or STALLED plus the one exact ask to
     LOOP-STATE.md and print it.

Rules: no new direction unless it traces to SPEC.md, a user answer, or a cited
RESEARCH.md line — log every assumption. One item per pass. No completion
claims without fresh pasted evidence.
