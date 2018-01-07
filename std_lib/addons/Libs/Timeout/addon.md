
Under certain circumstances progress can be lost from a delay. This will only
happen if the game crashes or is forcibly exited between the game being saved
and a timeout being added, deleted, or triggered.

If you must exit the game this way run `libs_dfhack_timeout.com -list` (which
forces an update) before you save the game.

I cannot fix this issue unless a "just before game save" event is added, which
is unlikely to happen.

In practice this exact circumstance is rare, as long as you exit the game
normally you will never have problems, and the worst that can happen is the
timeout runs a little long (a timeout will never be accidentally forgotten).
