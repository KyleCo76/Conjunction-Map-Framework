Task 12 standalone ask source input for the Task 13 fixture build.

This is source input, not an installable pack. The art URL is a placeholder; Task 13
supplies distinct original art and verifies an uncontested pin type for the launch.
The source tests use Boat pins. No CMF provider-order setting or menu step is needed.

Names and payload suffixes are modCMFTestRev13AskEarly and modCMFTestRev13AskLate.
Both wrap UpdateUserMapPins, which still runs when a REDkit-compiled mod replaces
UpdateEntityPins. zz_ask_late.ws (outside CMF's wrapper) appends Late before calling
the game; aa_ask_early.ws (inside it) appends Early after.
Tests also execute the reverse append order. Default folder order selects Early
in both cases. Start E uses AskLate alone, without the framework or menu add-on.

Made by Kyle with the help of AI tools (Claude and ChatGPT)
