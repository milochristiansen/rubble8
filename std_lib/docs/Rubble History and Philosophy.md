
Rubble History:
====================================================================================================

When I first started modding Dwarf Fortress I had a set of little mods I liked to apply before I
would play, small things like an extra workshop and a few small reactions. These little mods were
hard to apply. Every time you wanted to use them in a different configuration you had to spend a
good 10-15 minutes editing the raws to get everything working together, not my idea of fun.

I started to make a simple little program that would merge raw sets together, and got it about half
done, when I discovered a program named Blast. Blast changed the way I looked at modding, basically
it brought all my programming instincts to life. As a computer programmer I am used to thinking
about encapsulating commonly used bits in generic structures that can be reused over and over, and
Blast provided a way to do that.

But Blast had some issues, I made suggestions (quite a few of which were implemented), but in the
end my needs differed from the vision of Blast's creator. So I made Rubble.

The early versions of Rubble were little more than slightly extended (but ultimately less flexible)
versions of Blast, but as time went on I extended and rewrote Rubble until it became the powerful
utility that it is today.

Rubble Philosophy:
====================================================================================================

Rubble is unlike any other Dwarf Fortress mod. Most mods provide a carefully tailored experience,
where every part is carefully designed to fit with every other part. Some mods are small and only
provide a few new things, some are large and change the whole game.

The problem with mods like this is not everyone likes the same things, my favorite feature may be
something you detest. Some mods like Masterwork partially alleviate this problem by allowing you to
disable things that you dislike, but making a mod configurable that way is a tremendous task and
creates a whole new category of bugs that only effect certain configurations.

Rubble goes in the opposite direction. Instead of providing a tailored experience Rubble provides
many little independent parts that can be assembled into a custom experience. Most mods cannot do
this even if they wanted to because the way Dwarf Fortress handles mods would make it so much work
as to be nearly impossible.

So if it is too hard to assemble little bits seamlessly how does Rubble do it? The answer lies in
the "Rubble engine", a special utility that allows modders to write powerful scripts that generate
the necessary "glue". Most of the time the needed glue is relatively common to mods in general, so
Rubble can reuse it over and over with minimal modder effort. I just need to tell the engine in
general terms how something should be attached and Rubble figures out the details.

Rubble was designed (and then as I got a clearer view of how things should work, redesigned) from
the ground up to make it very easy to assemble coherent wholes from dissimilar parts, a task it does
very well. Obviously for this to be possible the parts need to be designed to allow them to fit
together, I call this design pattern "the Rubble philosophy".

For a mod to fit the Rubble philosophy it should satisfy as many of the following conditions as possible.

* A mod should change only one thing, and do so in as flexible a manner as possible. This way it will
  mesh well with other changes, plus it neatly avoids the problem of a mod having one feature that
  someone likes, but bundled with a feature they dislike.
* Mods should detect other mods that change related things and adjust themselves so they fit together
  better. This way they can avoid feeling like a pile of random unconnected parts.
* A mod should work with as many other mods as possible, it is always preferable to find a way to
  make two dissimilar mods work rather than forbidding that combination. Just because you think two
  features don't go well together doesn't mean everyone else will.

The Rubble philosophy can be summed up as: "many little things are better than a single big one, as
the little things can be easily assembled into something big, while the big thing cannot be easily
decomposed into many little ones". It is easier to make a connection between two things than it is
to separate two things already connected, so make your addons as small as possible.

Rubble goes out of it's way to make these tenets easy to follow. All of the default addons are
designed to mesh well together, and many of them provide interfaces that can be used by third-party
addons to make seamless integration even easier.

Where possible content should be separated from functionality. If your addon adds a new system of
some kind it is best if it is split into two parts: one that adds a generic implementation of the
system (for example `addon:Libs/Powered`) and one (or more) that use this implementation to
provide actual game content (the addons in the `addon:User/Powered` addon group, to continue the
previous example). This way if other modders want to add their own version of the system (or you want
to make a version that is compatible with a total conversion mod later) they can build on the existing
framework.
