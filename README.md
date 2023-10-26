# Space Exploration Zone Combinator
Combinator that outputs detailed information about the zone in which it is placed. Inspired by Baisius's discord suggestion.
![](mod-portal/combinator-example.png)

## Features
1. Introduces 4 new virtual signals.
1. Introduces a special 'zone combinator' that's effectively a constant combinator that is automatically built with a number of preset signals.
  1. Zone id, set on a channel corresponding to the zone type.
  1. Radius
  1. Day length, set on a new virtual signal and measured in ticks.
  1. Solar, solar efficiency with 100% = 100.
  1. Threat, as presented by the Universe Explorer, 100% = 100.
  1. Water, if present a water signal of 1 is set (waterless is just the lack of water).
  1. Biter Meteors, if present a meteor signal of 1 is set.
  1. Plagued, if present a plague rocket signal of 1 is set.
  1. Life Support, if present a life support canister signal of 1 is set.
  1. Core Fragment Type, if present a core fragment of the appropriate type will be used as a signal with value 1.
  1. Robot Interference, either wind or radiation is set on a new virtual signal and measured as presened by the Universe Explorer with a 100x scaling factor (1.00 = 100)
  1. Resources, frequency, size, and richness are multiplied together, 100% = 10,000.

## Limitations
1. Solar efficiency is currently not implemented (always reads as 100%).
1. Many of the units the combinators put out are capricious. Day length is in ticks, threat and solar are in percent (100 = 100%), resources(ore/oil) are in 1/100 of a percent (10k = 100% on mapgen settings), radius and robot interference are in in game units, flags like water, life support, plagued, and core type are flags with a value of 1 if present. 
1. If a plague rocket converts the primary resource of a zone from vitamelange to coal, the zone combinator primary resource output will not update until it is rebuilt.

## Combinator Mask
1. The source for this mod contains a mask for constant combinator tint for its entity and item - it should make adding different colored combinators easier in other mods.

## Credits
1. [test447](https://mods.factorio.com/user/test447) - code, combinator mask
1. [berggen](https://mods.factorio.com/user/berggen) - code
1. https://emojipedia.org/twitter/twemoji-15.0.1 - virtual signal emoji