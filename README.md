# bountiful.ash

> :paw_prints: a better bounty script :paw_prints:

## Installation

To install this script in KolMafia, simply use the following command in the gCLI:

`git checkout loathers/bountiful`

## Configuration

The script uses the following properties to determine behavior:

Property                      | Default Value     | Description
----------------------------- | ----------------- | -----------------------------------------------------------------------
bountiful.useBanisher         | false             | Whether or not to banish non-bounty monsters within the bounty location
bountiful.useCopier           | false             | Whether or not to copy the bounty monster using Spooky Putty/Rain-Doh
bountiful.useFax              | false             | Whether or not to fax in the bounty monster
bountiful.useFreeKill         | false             | Whether or not to kill the bounty monster with Power pills
bountiful.maxBanishCost       | autoBuyPriceLimit | Maximum price willing to spend on individual banishers
bountiful.maxSpecialCost      | autoBuyPriceLimit | Maximum price willing to spend on special bounty content unlockers
bountiful.automaticallyGiveup | false             | Whether or not to "Give up" bounties which cannot be accessed
bountiful.useAllOlfactCharges | false             | Whether or not to use all 3 olfaction charges. Uses up to 2 when false 

To set a property, simply type the following into the gCLI:

`set [insert property here] = [insert value here]`

A relay settings will be coming soon:tm:.

## Usage

Once the script is installed, use the following commands to do begin hunting:

Command      | Description
------------ | --------------------------------------------------
hunt easy    | Hunt the "easy" bounty
hunt hard    | Hunt the "hard" bounty
hunt special | Hunt the "special" bounty
hunt optimal | Hunts the bounty with the fewest items required
hunt all     | Hunts all possible bounties in order of item count

So, an example run could be: `bountiful hunt all`.

## Miscellaneous Information
This script is still in the "beta" stages and has been tested but not thoroughly, bug reporting is appreciated.

The code is documented using JavaDoc/JSDoc style comments if you are interested in taking a peek at the source code.

This script is forked from RESPRiT (https://github.com/RESPRiT/bountiful). Which was adapted (but very different) from AutoBHH, originally by izchak and majorly revised by Raorn and Zarqon. Thank you all for your contributions to this script.

Feel free to provide feedback of any kind!
