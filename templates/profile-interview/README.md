# profile-interview

A guided way to build a personal Claude profile (the "who I am and how to talk to me" file) without staring at a blank page.

Most people write their CLAUDE.md or custom-instructions file from scratch, which means a blank box and a vague sense they're forgetting something. This flips it: you paste one file into a fresh Claude conversation, say "run this," and Claude **interviews you** one question at a time, then assembles the finished profile for you to save.

## The idea: three dials before the questionnaire

The interview front-loads how Claude should *behave*, because that shapes every reply, and it does it with pick-a-style menus instead of open questions:

1. **Voice (how it talks).** Pick from four previewed personalities (dry & direct, warm & encouraging, neutral & professional, playful companion), like choosing a character voice in a game. Each comes with a one-line preview so you hear the difference before you commit.
2. **Working style (how it acts).** Same menu trick: expert peer, patient explainer, get-it-done operator, thought partner.
3. **Expression (the play layer).** Independent on/off toggles for things like a mood face at the top of each reply, free emoji, the occasional poem, and two-way feedback. Separate from voice, so a buttoned-up tone can still keep whatever sparks you want.

Claude adopts your picks immediately and runs the *rest* of the interview in that voice, so you feel your choice and can adjust mid-stream.

## Why it's built this way

- **Menus beat blank pages.** "Describe your ideal tone" is hard. "Pick A, B, C, or D, here's a preview of each" is easy, especially on a phone.
- **Sensitive stuff comes later, on purpose.** Family, health, finances, and relationships sit after the tone is set, once there's a little rapport, and every one is skippable.
- **Two standing guardrails are baked in.** Don't invent facts about your life (ask, or say "I don't know"), and trust the live conversation over the stale profile. These are the rules that keep an assistant trustworthy over time.
- **It plans for going stale.** The last section sets up when to refresh, and the hand-off tells you how to actually save the result so Claude loads it next time.

## How to use it

1. Open a fresh Claude conversation (claude.ai, the desktop or mobile app, or Claude Code).
2. Paste the contents of [`INTERVIEW.md`](INTERVIEW.md), or upload the file, and say **"run this."**
3. Answer the questions. Skip anything you don't want to share. Ramble; it's capturing your voice.
4. At the end, Claude outputs your finished profile and tells you where to save it (Settings > Personal preferences, a Project's instructions, or a `CLAUDE.md`).

[`EXAMPLE.md`](EXAMPLE.md) shows a finished profile from a fictional person, so you can see what "done" looks like.

## License

MIT. See the [repo LICENSE](../../LICENSE).
