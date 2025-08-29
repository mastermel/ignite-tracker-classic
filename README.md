# IgniteTracker
Tracks Ignite and Scorch debuffs

Authors:
- Moxxe <Summit> / Benediction (NA) / Discord Neko/Moxey#2051
- Kortan <Beyond Honor> / Dreamscythe (NA) / Discord: Mel#0544

## Ignite
- Provides progress bar that displays the current owner of the Ignite, their threat and the current tick
- Only tracks on current target since they won't last long on trash anyway

## Scorch
- Progress bar that displays the current stack and your own threat
- Will work across multiple targets
- Stacks 1-5 are reliably detected since the combat log tracks them
- After 5 stacks it just goes by Scorch damage, so it WILL update the timer even if Fire Vulnerability is resisted
- Bar will flash blue if the Fire Vulnerability portion of Improved Scorch is resisted, which matters after 5 stacks

## Crit tracking
- Separate window that shows the 10 most recent fire crits and who supplied them (shows who is rolling the Ignite)
- Will also output the final damage done by the Ignite when it falls off

## Combustion Tracker (BETA)
- Shows a timer for each mage that counts up from when they use Combustion as well as number of crits since activated
- Will automatically stop after 3 minutes in case the caster is out of range when their buff expires

## Other
- Will broadcast to other users of the addon to let them know if you are talented for Ignite or Improved Scorch
- This is helpful to know when tracking crits to see who is rolling the Ignite
- If it is unknown if a mage is talented into Ignite, the addon just assumes they are if they are casting fire spells
- Can enable "Frostmode" to track frost spell crits

## Usage
- Move the bars to where you want them, nothing else required
- Click minimap button to lock/unlock the bars to move them
  `/ignitetracker lock, /ignitetracker unlock or /ignitetracker move`
- Shift+click to show/hide the crit window
  `/ignitetracker crit`
- Right click to toggle Frostmode
  `/ignitetracker frostmode on (or 1), /ignitetracker frostmode off (or 0)`
- Shift+Right click to hide minimap icon 
  `/ignitetracker minimap 0, /ignitetracker minimap 1`

## Possible future enhancements
- Allow customization of bar size and colors
- Sync between users of the addon to prevent combat log range issues
- Make crit tracker scrollable

## Revision History
2020-08-25 - 1.08 - Crit tracker should now stay hidden, fixed bug with Scorch icon when switching targets
2020-08-12 - 1.07 - Non-latin clients will now use default game fonts
2020-08-10 - 1.06 - Reworked moving/anchoring
2020-07-31 - 1.05 - Fixed issue with Combustion Tracker, added number of crits since cast
                  - Added numeric timers to Ignite and Scorch
                  - Move threat to the left of icons
                  - Added Ignite stack to the right of Ignite icon
2020-07-25 - 1.04 - Added Combustion Tracker
2020-07-14 - 1.03 - Use localized name for Scorch
2020-07-09 - 1.02 - Changed to Blizzard threat API, added player threat to Scorch bar
2020-05-19 - 1.01 - Added threat of current Ignite holder
2020-02-29 - 1.00 - Timers should now properly display at anchor position
                  - Minimap icon will stay shown if option is set
2019-08-14 - 0.93 - Reworked a lot of spell handling due to Blizzard changes between closed beta and stress test 3
2019-06-23 - 0.92 - Switched to SpellID instead of SpellName for debuff detection so it works for all localizations
                  - Updated frame position saving
2019-06-15 - 0.91 - Fixed bug where no target was selected when Scorch is applied
                  - Fixed bug when Scorch debuff drops off and doesn't reapply properly
2019-06-09 - 0.90 - Classic WoW Beta release