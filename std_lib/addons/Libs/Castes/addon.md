
This is used by the standard base, so it is active most of the time.

**The scripts that power these templates do not use the shared script registry yet!**
This means that you will have to use Lua to interface with these templates if you need
to work with them at a low level (which should not be required in most cases). Any script
code that interfaces with these templates directly may break without notice!

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!REGISTER_CREATURE;<ID>;<DESCRIPTION>;<MALE>;<FEMALE>;<ADJ>}

Register a creature with the caste library, this needs to be done before any other templates are
called for this creature.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{!DEFAULT_CASTE;<CREATURE>;<ID>;<DESC_NAME>;<NAME>;<NAME_PLUR>;<POPM>;<POPF>;<DESC>;<BONUS>}

Create a new caste for the specified creature using the provided information.

As it's name suggests this template is generally used for the default caste.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{CASTE;<CREATURE>;<ID>;<DESC_NAME>;<NAME>;<NAME_PLUR>;<POPM>;<POPF>;<DESC>;<BONUS>}

Create a new caste for the specified creature using the provided information.

Exactly like `!DEFAULT_CASTE` but for all the other castes you may want to add.

 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	{#CASTE_INSERT;<CREATURE>}

Write the generated castes here.
Place this in your creature file where you want the castes to be added.
