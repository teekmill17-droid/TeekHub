# TeekHub

A multi-game Roblox hub. One loadstring, every supported game — it detects the
place you are in and loads the matching script, so you never change the paste.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/teekmill17-droid/TeekHub/main/Loader.lua"))()
```

New games and fixes reach you on your next execute. There is nothing to update.

---

## Supported

| Game | Highlights |
|---|---|
| Sniper Arena | ESP, FOV assistance, silent options |
| Blade Ball | Auto parry, spam control, ESP |
| Blox Fruits | Farm, chest/fruit ESP, teleports |
| Fisch | Auto fish, perfect-cast timing, spot teleports |
| Jailbreak | Vehicle tools, ESP, auto-rob |
| Anime Battle Arena | Combat helpers, ESP |
| All Star Tower Defense | Auto battle, 3x speed lock, summon viewer *(beta)* |

Running something unsupported? The hub prints the place and universe ID on
start — post those in Discord and it becomes a request.

---

## What's in it

**ESP that works where others don't.** Boxes, skeletons, chams, health bars,
tracers, off-screen arrows, distance fade, visibility colouring and a radar.
It renders through its own GUI pipeline rather than the Drawing API, because
several popular executors accept Drawing calls and render nothing at all.

**Config profiles.** Save a named profile and it appears in a dropdown you pick
from — no retyping a name and hoping you spelled it the same way. Set one to
load on start if you want it back automatically. Share codes turn a setup into
a short string you can paste to someone else.

**A status panel that tells you the truth.** Every dependency the script has is
health-checked at runtime. When a game updates and something moves, the panel
names what broke, instead of you finding out by watching nothing happen.

**Safe mode.** Anything that talks to the server is labelled as such, so you can
run client-only when you want to be careful.

**Webhooks.** Session reports to Discord with real numbers, traced to their
source rather than scraped off a label.

**Performance controls.** FPS cap, no-render, hide map, performance mode.

---

## Interface

Dark, purple, animated, opening on a Rinnegan that fills as it loads. Tabs are
searchable, and there is a UI Scale slider on the Interface tab if the window
is too large or too small for your screen.

---

## Notes

- Requires an executor with `loadstring` and `game:HttpGet`.
- **Settings do not persist unless you save them.** Save a profile on the Config
  tab, and optionally set it to load on start. There is also a "Keep Settings
  Between Sessions" toggle there if you would rather it saved continuously.
- **The hub does not relaunch itself after a teleport.** Run the loadstring
  again when a game moves you between places. This is deliberate — a hub that
  re-injects itself into every session you join is worse than one you start
  when you want it.
- The hub reads a small control file on start, so an outage or a breaking game
  update can be announced to everyone at once.
- Everything here is provided as-is, for use at your own risk.

## Links

Discord — *(invite goes here)*
