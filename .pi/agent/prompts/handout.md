---
description: Create a handout or load one by ID
argument-hint: "[ID]"
---

Use the `handout` skill. The optional identifier is `${ARGUMENTS:-not supplied}`. If it is not
supplied, create a new handout and report its generated ID. Otherwise load that exact ID and
continue from it.
