
This addon adds a system where a workshop will periodically queue a reaction job for your dwarves to carry out. This
happens automatically, allowing industries that produce products periodically, but only if a dwarf is available to
provide labor.

This system was designed for simulating bee hives, fish farms, herb gardens, etc.

The auto-worker system uses the same DFHack plugin that enables powered workshops, so you cannot use this system together
with the powered workshop system on a single workshop.

Note: This library does not properly support reactions with reagents. It is possible to add reagents, but it is a PITA
as you need to provide a function to manually create the needed `job_item` references. I suppose I could write a function
to convert a `reaction_reagent` to a `job_item`, but it would be a real pain, so not right now.
