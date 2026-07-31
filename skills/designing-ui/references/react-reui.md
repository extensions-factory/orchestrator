# React and ReUI

Confirm React from installed project files before using this branch.

Check for the registry toolchain: Tailwind, shadcn, or a configured component registry. If it is absent, ask the human whether to adopt it; do not decide for them. If it is present or the human approves adoption, use:

**REQUIRED SUB-SKILL:** Use reui

Follow the ladder: if the human declines, native React and browser primitives are the correct answer. Worked example from Probe B: “a bare Electron app with only `react` and `react-dom` — no Tailwind, no shadcn, no registry”; CSS grid, a `<table>`, and native inputs covered four stat tiles and navigation without adding a registry toolchain.
