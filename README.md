# TeekHub

One loadstring for every game I support. It checks what place you're in and
loads the right script, so you never swap the paste out.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/teekmill17-droid/TeekHub/main/Loader.lua"))()
```

When I add a game or fix something it's there on your next execute. Nothing to
re-download.

---

## Games

| Game | What it does |
|---|---|
| Sniper Arena | ESP, FOV help, silent options |
| Blade Ball | Auto parry, spam control, ESP |
| Blox Fruits | Farm, chest and fruit ESP, teleports |
| Fisch | Auto fish, perfect cast timing, spot teleports |
| Jailbreak | Vehicle tools, ESP, auto rob |
| Anime Battle Arena | Combat helpers, ESP |
| All Star Tower Defense | Auto battle, 3x speed lock, summon viewer *(beta)* |
| RH2 The Journey | Auto green shot meter, keycap overlay, accuracy stats |
| My Animal Farm | Auto roll, buy, place, hatch, trait feeding, junk selling |
| Steal an Egg | Auto steal by area, size and rate *(read the warning)* |
| Sell Ores | Auto roll and buy by rarity, sell, boost, upgrades, plots, gems |
| Speedsters Beyond | Auto ascend, jobs, quests, orbs, treadmill, titles |

Playing something that isn't on here? The hub prints the place and universe ID
when it starts. Drop those in the Discord and I'll look at it.

**Steal an Egg has an anti-cheat that kicks for cheating.** I haven't worked out
what sets it off yet. The hub warns you and asks before it loads anything in that
game — don't run it on an account you care about.

---

## What you get

**ESP.** Boxes, skeletons, chams, health bars, tracers, off-screen arrows,
distance fade, visibility colours, radar. It draws with GUI instances instead of
the Drawing API because a lot of executors take Drawing calls and then render
nothing.

**Config profiles.** Save a setup under a name and pick it from a dropdown. Set
one to load on start if you want it back every time. Share codes turn a config
into a string you can paste to someone.

**Status tab.** Everything the script depends on gets checked while it runs, so
when a game updates and something moves you get told what broke instead of
sitting there wondering why nothing happens.

**Safe mode.** Anything that talks to the server is marked, so you can stay
client-side if you want to be careful.

**Webhooks.** Session reports to Discord with real numbers.

**Performance.** FPS cap, no render, hide map, performance mode.

---

## Interface

Dark and purple, opens on a Rinnegan that fills while it loads. Tabs are
searchable and there's a UI scale slider on the Interface tab if it's too big or
small on your screen.

---

## Worth knowing

- Needs an executor with `loadstring` and `game:HttpGet`.
- **Nothing is on when you first load it.** Turn on what you want, then save it
  as a profile on the Config tab if you want it back next time.
- **Settings don't save unless you save them.** Config tab, save a profile, set
  it to load on start. There's a "Keep Settings Between Sessions" toggle there
  too.
- **It won't reload itself after a teleport.** Run the loadstring again. That's
  on purpose — a hub that re-injects into every server you join is worse than
  one you start when you actually want it.
- It reads a small control file on start so I can push a notice or shut things
  off if a game update breaks something.
- Use at your own risk.

## Links

Discord — https://discord.gg/bVfh78hkc
