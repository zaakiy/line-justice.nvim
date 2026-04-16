# line-justice.nvim – A beautiful line numbering plugin for NeoVim

**Absolute justice with relative context**

## LineJustice - Absolute Justice with Relative Context

### The Problem

**You use relative line numbers in NeoVim. Your colleagues don't.**

You're pair programming with a colleague. They say, "Hey, there's a bug on line 16." You look at your screen – line 16 above or line 16 below? They're looking at a different part of the file. Confusion ensues. You both waste 5 minutes trying to find the same line.

Or worse: you're in a code review, and someone points to "the line with the bug" but you're scrolling through a 500-line file trying to find it. "Is it near the top? Middle? Bottom?" you ask. They don't know – they're just counting from where they are.

### The Solution

**LineJustice** shows you both numbers at once.

Every line displays its **absolute line number** (the true position in the file: 42, 127, 500) *and* its **relative line number** (how far it is from your cursor: 5 lines above, 3 lines below). 

Now when your colleague says "line 42," you both see the same thing. When you're reviewing code, you can instantly say "3 lines down from the cursor" and they know exactly where you mean—whether they're looking at the top, middle, or bottom of the file.

### The Story

**Before LineJustice:**
- "Which line?"
- "Line 42!"
- "I don't see it..."
- *5 minutes of confusion*

**With LineJustice:**
- "Which line?"
- "Line 42!"
- *Both instantly see: `42  16` (absolute 42, relative 16 lines away)*
- "Got it. Fixed."

### Why It Matters

- **Pair programming** becomes seamless—no more "which line are you looking at?"
- **Code reviews** are faster—point to exact locations instantly
- **Remote collaboration** works better—everyone sees the same coordinates
- **Debugging** is clearer—reference lines with absolute certainty
- **Teaching** is easier—show students exactly where to look

**LineJustice delivers absolute justice to line number confusion.**


