---
name: peon-ping-log
description: Log exercise reps for the Peon Trainer. Use when user says they did pushups, squats, or wants to log reps. Examples - "/peon-ping-log 25 pushups", "/peon-ping-log 30 squats", "log 50 pushups".
---

# peon-ping-log

Log exercise reps for the Peon Trainer.

## Usage

Run:

```bash
peon trainer log <count> <exercise>
```

Where `<count>` is the number of reps and `<exercise>` is `pushups` or `squats`.

Report the output to the user. The command will print the updated rep count and play a trainer voice line.

## If trainer is not enabled

If the output says trainer is not enabled, tell the user to run `peon trainer on` first.

## Check status

If the user asks for their progress after logging:

```bash
peon trainer status
```
