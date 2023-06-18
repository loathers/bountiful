/******************************************************************************
* Bountiful by loathers
* https://github.com/loathers
*
* Forked from RESPRiT
* -Which was adapted from AutoBHH:
*  -Originally by izchak
*  -Major revisions by Raorn and Zarqon
******************************************************************************/
script "Bountiful";
since r26691;

/********************************
Custom Properties and Default Values (* indicates unused):
 - bountiful.useBanisher : false
 - bountiful.useCopier : false
 - bountiful.useFax : false
 - bountiful.useRunaway* : false
 - bountiful.useFreeKill : false
 - bountiful.maxBanishCost : autoBuyPriceLimit
 - bountiful.maxSpecialCost : autoBuyPriceLimit
 - bountiful.maxRunawayCost : autoBuyPriceLimit
 - bountiful.automaticallyGiveup : false
 - bountiful.useAllOlfactCharges : false
********************************/

/*
TODO:
 - handle elemental airport properties bug
 - reorder functions/general organization
 - script information for third-party comprehension
 - runaway logic
 - romantic arrow support
*/

//----------------------------------------
// Global Variables
item LAST_BANISH; // for debugging/preventing a mafia bug from breaking things
location LAST_LOCATION;

bounty current;

//----------------------------------------
// Constant Variables

// Properties
boolean useBan = get_property("bountiful.useBanisher").to_boolean();
boolean useCopier = get_property("bountiful.useCopier").to_boolean();
boolean useFax = get_property("bountiful.useFax").to_boolean();
boolean useRun = get_property("bountiful.useRunaway").to_boolean();
boolean useKill = get_property("bountiful.useFreeKill").to_boolean();
int maxBanish = get_property("bountiful.maxBanishCost").to_int();
if(maxBanish == 0) maxBanish = get_property("autoBuyPriceLimit").to_int();
int maxSpecial = get_property("bountiful.maxSpecialCost").to_int();
if(maxSpecial == 0) maxSpecial = get_property("autoBuyPriceLimit").to_int();
boolean giveup = get_property("bountiful.automaticallyGiveup").to_boolean();
boolean useAllOlfactCharges = get_property("bountiful.useAllOlfactCharges").to_boolean();

// Types
string EASY = "easy";
string HARD = "hard";
string SPECIAL = "special";

// Banishers
int[item] BAN_ITEMS = {
  $item[Louder Than Bomb] : 20,
  $item[crystal skull] : 20,
  $item[tennis ball] : 20,
  $item[divine champagne popper] : 5
};

// Unlockers
item[location] CONTENT_ITEMS = {
  $location[Anger Man\'s Level] : $item[jar of psychoses (The Crackpot Mystic)],
  $location[Pirates of the Garbage Barges] : $item[one-day ticket to Dinseylandfill],
  $location[the Ice Hotel] : $item[one-day ticket to The Glaciest],
  $location[The Stately Pleasure Dome] : $item[tiny bottle of absinthe],
  $location[Domed City of Grimacia] : $item[transporter transponder],
  $location[LavaCo&trade; Lamp Factory] : $item[one-day ticket to That 70s Volcano],
  $location[The Clumsiness Grove] : $item[devilish folio],
  $location[The Nightmare Meatrealm] : $item[jar of psychoses (The Meatsmith)],
  $location[Sloppy Seconds Diner] : $item[one-day ticket to Spring Break Beach],
  $location[An Incredibly Strange Place (Bad Trip)] : $item[astral mushroom],
  $location[the Red Queen\'s Garden] : $item[&quot;DRINK ME&quot; potion],
  $location[Mt. Molehill] : $item[llama lama gong],
  $location[The Jungles of Ancient Loathing] : $item[empty agua de vida bottle],
  $location[Chinatown Shops] : $item[jar of psychoses (The Suspicious-Looking Guy)],
  $location[the Secret Government Laboratory] : $item[one-day ticket to Conspiracy Island]
};

// "No Banish" Locations
// TODO: incomplete? a is_banishable() function/property would be great..
boolean[location] NO_BANISH_LOCATIONS = {
  $location[Pirates of the Garbage Barges] : true,
  $location[the Secret Government Laboratory] : true,
  $location[Sloppy Seconds Diner] : true
};

//----------------------------------------
// Private Bounty Functions

/**
* Returns the current bounty item of the given type
* @param {string} type - the bounty type
* @returns {bounty} - the current bounty item of the given type, either taken
                      or untaken
*/
bounty _bounty(string type) {
  bounty ret;
  switch(type) {
    case EASY:
      ret = to_bounty(get_property("currentEasyBountyItem"));
      if(ret == $bounty[none]) {
        return to_bounty(get_property("_untakenEasyBountyItem"));
      } else {
        return ret;
      }
    case HARD:
      ret = to_bounty(get_property("currentHardBountyItem"));
      if(ret == $bounty[none]) {
        return to_bounty(get_property("_untakenHardBountyItem"));
      } else {
        return ret;
      }
    case SPECIAL:
      ret = to_bounty(get_property("currentSpecialBountyItem"));
      if(ret == $bounty[none]) {
        return to_bounty(get_property("_untakenSpecialBountyItem"));
      } else {
        return ret;
      }
    default:
      abort("_bounty: Invalid bounty type");
  }
  return $bounty[none];
}

/**
* Returns if the bounty of the given type is currently taken
* @param {string} type - the bounty type
* @returns {int} - if the bounty of the given type is currently taken
*/
boolean _accepted(string type) {
  switch(type) {
    case EASY:
      return get_property("currentEasyBountyItem") != "";
    case HARD:
      return get_property("currentHardBountyItem") != "";
    case SPECIAL:
      return get_property("currentSpecialBountyItem") != "";
    default:
      abort("_accepted: Invalid bounty type - " + type);
  }
  return false;
}

// @Overload
boolean _accepted(bounty b) {
  return _accepted(b.type);
}

/**
* Returns the number of bounty items acquired of the given type
* @param {string} type - the bounty type
* @returns {int} - the bounty item count if the type is accepted,
                   -1 if the given type is not currently accepted
*/
int _count(string type) {
  string[int] prop;
  if(_accepted(type)) {
    switch(type) {
      case EASY:
        prop = get_property("currentEasyBountyItem").split_string(":");
        return prop[1].to_int();
      case HARD:
        prop = get_property("currentHardBountyItem").split_string(":");
        return prop[1].to_int();
      case SPECIAL:
        prop = get_property("currentSpecialBountyItem").split_string(":");
        return prop[1].to_int();
      default:
        abort("_count: Invalid bounty type");
      return -666;
    }
  } else {
    return -1;
  }
}

/**
* Returns the number of bounty items remaining of the given type
* @param {string} type - the bounty type
* @returns {int} - the bounty items remaining if the type is accepted,
                   -1 if the given type is not currently accepted
*/
int _remaining(string type) {
  int count = _count(type);
  int total = _bounty(type).number;

  if(count >= 0) {
    return total - count;
  } else {
    return count;
  }
}

// @Overload
int _remaining(bounty b) {
  return _remaining(b.type);
}

//----------------------------------------
// Helper Functions

/**
* Returns the number of copies available daily
* @returns {int} - the number of copies available daily, does not subtract
                   copies used that day
*/
int copies_available() {
  int copies = 0;

  if(available_amount($item[Rain-Doh black box]) > 0) {
    copies += 1;
  }

  if(available_amount($item[Spooky Putty sheet]) > 0) {
    copies += 1;
  }

  if(copies > 0) {
    copies += 4;
  }

  return copies;
}

/**
* Purchases banishes that are within budget
* @returns {boolean} - if at least one banisher was purchased
*/
boolean buy_banishers() {
  int count = 0;

  foreach banisher in BAN_ITEMS {
    if(item_amount(banisher) < 1) {
      count += buy(1, banisher, maxBanish);
    }
  }

  return count > 0;
}

/**
* Returns if the given location allows banishing
* @param {location} l - the location to check
* @returns {boolean} - true if the location allows banishing
*/
boolean can_banish(location l) {
  return !(NO_BANISH_LOCATIONS contains l);
}

/**
* Uses an item with the given combat filter, like use() but with combat filters
* @param {item} it - the item to use
* @param {string} filter - the combat filter to use
* @returns {boolean} - true if the item was used successfully
*/
boolean use_combat(item it, string filter) {
  string page = visit_url("inv_use.php?&pwd&which=3&checked=1&whichitem=" + it.to_int());

  if(page.contains_text("You don't have the item you're trying to use")) {
    return false;
  }

  if(page.contains_text("You're fighting")) {
    run_combat(filter);
  }

  return true;
}

/**
* Helper function to add additional copies of the bounty monster to the queue
* @param {monster} opp - the current enemy monster
* @param {boolean} speculate - only notifies user of skill being used when false
* @returns {string} - combat action if an action can be taken, otherwise empty ""
*/
string addBountyToQueue(monster opp, boolean speculate) {

  // confirm we can survive 5 rounds
  if((expected_damage(opp) * 5) > my_hp()) {
    // can't survive, focus on killing
    return "";
  }

  // Transcendent Olfaction. Save 1 olfact for farming purposes, depending on pref
  int olfactsToUse = useAllOlfactCharges ? 3 : 2;
  monster olfactedMonster = get_property("olfactedMonster").to_monster();
  if(olfactedMonster != opp && have_skill($skill[Transcendent Olfaction]) && get_property("_olfactionsUsed").to_int() < olfactsToUse)
  {
    if(!speculate) print("Sniffing this one!", "blue");
    return "skill Transcendent Olfaction";
  }

  // Gallapagosian Mating Call
  monster gallapagosMonster = get_property("_gallapagosMonster").to_monster();
  if(gallapagosMonster != opp && have_skill($skill[Gallapagosian Mating Call]) && my_mp() >= 30)
  {
    if(!speculate) print("Mating call on this one!", "blue");
    return "skill Gallapagosian Mating Call";
  }

  // Get a Good Whiff of This Guy
  monster nosyNoseMonster = get_property("nosyNoseMonster").to_monster();
  if(nosyNoseMonster != opp && have_skill($skill[Get a Good Whiff of This Guy]))
  {
    if(!speculate) print("Nosy Nose smelling this one!", "blue");
    return "skill Get a Good Whiff of This Guy";
  }

  // Curse of Stench. Specific to challenge path Avatar of Ed the Undying
  monster stenchCursedMonster = get_property("stenchCursedMonster").to_monster();
  if(stenchCursedMonster != opp && have_skill($skill[Curse of Stench]) && my_mp() >= 35)
  {
    if(!speculate) print("Casting Curse of Stench on this one!", "blue");
    return "skill Curse of Stench";
  }

  // Motif. Specific to plyaing as Jazz Agent in challenge path Avatar of Shadows Over Loathing
  monster motifMonster = get_property("motifMonster").to_monster();
  if(motifMonster != opp && have_skill($skill[motif]) && my_mp() >= 50)
  {
    if(!speculate) print("Casting Motif on this one!", "blue");
    return "skill Motif";
  }

  return "";
}

/**
* Determines if desired monster is in our received fax.
* If it is not, send fax to clear inventory
* @param {monster} enemy - desired fax target
* @returns {boolean} - true if have photocopy of desired monster
*/
boolean checkFax(monster enemy)
{
  if(item_amount($item[photocopied monster]) == 0)
  {
    cli_execute("fax receive");
  }

  if(get_property("photocopyMonster") == enemy.to_string())
  {
    return true;
  }

  cli_execute("fax send");
  return false;
}

/**
* Attempts to fax and fight a monster. 
* Will try CheeseFax first and if fails attempts EasyFax
* @param {monster} enemy - desired fax target
* @returns {boolean} - true if desired monster was faxed and fought
*/
boolean handleFaxMonster(monster enemy)
{
  if(get_property("_photocopyUsed").to_boolean())
  {
    return false;
  }
  if(contains_text(get_property("_bountiful.FailedFaxes"), enemy))
  {
    return false;
  }
  if(!is_unrestricted($item[deluxe fax machine]))
  {
    return false;
  }
  if(item_amount($item[Clan VIP Lounge Key]) == 0)
  {
    print("Faxing is enabled in Bountiful but you don't have a Clan VIP Lounge Key!", "red");
    return false;
  }
  if(!(get_clan_lounge() contains $item[Deluxe Fax Machine]))
  {
    print("Faxing is enabled in Bountiful but the clan you are in doesn't have a fax machine!", "red");
    return false;
  }

  print("Using fax machine to summon " + enemy.name, "blue");

  if(item_amount($item[Photocopied Monster]) != 0)
  {
    if(get_property("photocopyMonster") == enemy)
    {
      print("We already have a copy of the monster we want to fax!", "blue");
      use_combat($item[photocopied monster], "combat");
      return true;
    }
    else
    {
      print("We already have a photocopy and not the one we wanted. Disposing of bad copy.", "blue");
      cli_execute("fax send");
    }
  }

  print("Faxing: " + enemy + " using cheesefax.", "green");
  chat_private("cheesefax", enemy.to_string());
  for(int i = 0; i < 3; i++)
  {
    //wait 10 seconds before trying to get fax
    wait(10);
    if(checkFax(enemy))
    {
      //got correct photocopied monster! Fight it now if desired
      print("Sucessfully faxed " + enemy);
      use_combat($item[photocopied monster], "combat");
      return true;
    }
  }

  print("Faxing: " + enemy + " using easyfax.", "green");
  chat_private("easyfax", enemy.to_string());
  for(int i = 0; i < 3; i++)
  {
    //wait 10 seconds before trying to get fax
    wait(10);
    if(checkFax(enemy))
    {
      //got correct photocopied monster! Fight it now if desired
      print("Sucessfully faxed " + enemy);
      use_combat($item[photocopied monster], "combat");
      return true;
    }
  }

  print("Failed to use clan Fax Machine to acquire a photocopied " + enemy + ". Potentially this monster is not in the fax network.");
  if(!contains_text(get_property("_bountiful.FailedFaxes"), enemy))
  {
    string cur = get_property("_bountiful.FailedFaxes");
    if(cur != "")
    {
      cur = cur + ", ";
    }
    cur = cur + enemy;
    set_property("_bountiful.FailedFaxes", cur);
  }
  
  return false;
}

//----------------------------------------
// BHH Functions

/**
* Visits the BHH and possibly performs an action based on the query
* @param {string} query - the query to do BHH actions
* @returns {string} - the page text
*/
string visit_bhh(string query) {
  string page = visit_url("bounty.php?pwd"+query);
  return page;
}

// @Overload
string visit_bhh() {
  return visit_bhh("");
}

/**
* Accepts the bounty of the given type
* @param {string} type - the bounty type
* @returns {boolean} - false if the given bounty is already accepted
*/
boolean accept_bounty(string type) {
  if(_accepted(type)) {
    return false;
  }

  visit_bhh("&action=take"+_bounty(type).kol_internal_type);
  visit_bhh();
  return true;
}

// @Overload
boolean accept_bounty(bounty b) {
  return accept_bounty(b.type);
}

/**
* Cancels the bounty of the given type
* @param {string} type - the bounty type
* @returns {boolean} - false if the given bounty is not already accepted
*/
boolean cancel_bounty(string type) {
  if(!_accepted(type)) {
    return false;
  }

  string value = "";
  switch(type) {
    case EASY:
    case HARD:
      value = _bounty(type).kol_internal_type;
      break;
    case SPECIAL:
      value = "spe";
      break;
    default:
      abort("cancel_bounty: Invalid bounty type - " + type);
      break;
  }

  visit_bhh("&action=giveup_"+value);
  visit_bhh();
  return true;
}

/**
* Checks if the given monster is currently being hunted
* @param {monster} opp - the string representation of the monster to check
* @returns {boolean} - if the given monster is being hunted
*/
boolean is_hunted(monster opp) {
  // Checks if opp equals any of the current bounty monsters
  return opp == to_bounty(get_property("currentEasyBountyItem")).monster ||
         opp == to_bounty(get_property("currentHardBountyItem")).monster ||
         opp == to_bounty(get_property("currentSpecialBountyItem")).monster;
}

// @Overload
boolean is_hunted(string opp) {
  return is_hunted(to_monster(opp));
}

/**
* Returns the bounty with the smallest item count
* @returns {bounty} - the bounty with the smallest item count,
                      $bounty[none] if no bounties are available/active
*/
bounty optimal_bounty() {
  bounty[int] bounty_counts;
  bounty_counts[_bounty(EASY).number] = _bounty(EASY);
  bounty_counts[_bounty(HARD).number] = _bounty(HARD);
  bounty_counts[_bounty(SPECIAL).number] = _bounty(SPECIAL);

  int min = 696969;
  foreach count in bounty_counts {
    if(count < min && count != 0) {
      min = count;
    }
  }

  return bounty_counts[min];
}

/**
* Attempts to hunt the given bounty based on current settings and state:
*  - Will fax if bountiful.useFax is true and a fax is available
*  - Will use a copy if bountiful.useCopier is true and a copy is available
*  - Will adventure at a special content-unlockable location if the unlock
*    item costs less than or equal to bountiful.maxSpecialCost or the zone is
*    available
*  - Will adventure at a normal location if it is available
*  - Will give up a bounty if inaccessible and bountiful.automaticallyGiveup is true
* @param {bounty} b - the bounty to hunt
* @returns {boolean} - false if the bounty could not be hunted
*/
boolean hunt_bounty(bounty b) {
  accept_bounty(b.type); // doesn't do anything if already accepted
  print("There are " + _remaining(b.type).to_string() + " " +
        b.plural + " remaining!", "green");
  current = b;

  // TODO: Fax logic for doable inaccessible bounties
  if(useFax && !to_boolean(get_property("_photocopyUsed")) && !contains_text(get_property("_bountiful.FailedFaxes"), b.monster)) {
    handleFaxMonster(b.monster);
  // use copy if that's what we're doing and a copy is avilable
  } else if(useCopier && item_amount($item[Rain-Doh box full of monster]) > 0 &&
            to_monster(get_property("rainDohMonster")) == b.monster) {
    use_combat($item[Rain-Doh box full of monster], "combat");
  } else if(useCopier && item_amount($item[Spooky Putty monster]) > 0 &&
            to_monster(get_property("spookyPuttyMonster")) == b.monster) {
    use_combat($item[Spooky Putty monster], "combat");
  // if location is available or affordable, adventure there
  } else if(can_adventure(b.location) ||
            (b.type == SPECIAL &&
            mall_price(CONTENT_ITEMS[b.location]) <= maxSpecial)) {
    if(useBan)
      buy_banishers();

    // use Nosy Nose to add copies of bounty to the queue
    if(have_familiar($familiar[Nosy Nose]) && my_familiar() != $familiar[Nosy Nose])
      use_familiar($familiar[Nosy Nose]);

    // unlock special zone if currently not available
    if(!can_adventure(b.location)) {
      print("Mafia determined we can't adv at " + b.location, "blue");
      print("Attempting to unlock.", "blue");
      if(item_amount(CONTENT_ITEMS[b.location]) < 1)
        buy(1, CONTENT_ITEMS[b.location], maxSpecial);
      use(1, CONTENT_ITEMS[b.location]);
    }

    // prepare zone and check accessibility
    if(!can_adventure(b.location))
      abort("Couldn't prepare the zone for some reason");

    if($locations[The Haunted Pantry,The Black Forest,Inside The Palindome,The Outskirts of Cobb\'s Knob,Cobb\'s Knob Treasury,The Jungles of Ancient Loathing] contains b.location){
      int wantedCombatRate = 25;
      if(b.location == $location[The Black Forest]) {
        wantedCombatRate = 5;
      }
      if(b.location == $location[Cobb\'s Knob Treasury]) {
        wantedCombatRate = 15;
      }
      else if($locations[The Haunted Pantry,The Outskirts of Cobb\'s Knob] contains b.location) {
        wantedCombatRate = 20;
      }
      if(numeric_modifier("combat rate") < wantedCombatRate && have_effect($effect[The Sonata of Sneakiness]) > 0) {
        catch cli_execute("shrug The Sonata of Sneakiness");
      }
      if(numeric_modifier("combat rate") < wantedCombatRate && have_effect($effect[Musk of the Moose]) == 0) {
        if(have_skill($skill[Musk of the Moose]) && my_mp() >= mp_cost($skill[Musk of the Moose])) {
          catch cli_execute("cast Musk of the Moose");
        }
      }
      if(numeric_modifier("combat rate") < wantedCombatRate && have_effect($effect[Carlweather\'s Cantata of Confrontation]) == 0) {
        if(have_skill($skill[Carlweather\'s Cantata of Confrontation]) && my_mp() >= mp_cost($skill[Carlweather\'s Cantata of Confrontation])){
          catch cli_execute("cast Carlweather\'s Cantata of Confrontation");
        }
      }
    }
    //noncombats which let you choose the right monster or skip
    if($locations[The Castle in the Clouds in the Sky (Top Floor)] contains b.location){
      if(have_effect($effect[Carlweather\'s Cantata of Confrontation]) > 0) {
        catch cli_execute("shrug Carlweather\'s Cantata of Confrontation");
      }
      if(have_effect($effect[Smooth Movements]) == 0 && have_skill($skill[Smooth Movement]) && my_mp() >= mp_cost($skill[Smooth Movement])) {
        catch cli_execute("cast Smooth Movement");
      }
      if(have_effect($effect[The Sonata of Sneakiness]) == 0 && have_skill($skill[The Sonata of Sneakiness]) && my_mp() >= mp_cost($skill[The Sonata of Sneakiness])) {
        catch cli_execute("cast The Sonata of Sneakiness");
      }
    }
    adv1(b.location, 1, "combat");

  } else {
    // turns out we're doing nothing
    print("Can't access bounty location: " + b.location, "orange");
    print("Manually unlock bounty zone and run me again if you want to complete this bounty", "orange");
    if(giveup) {
      print("Giving up bounty based on pref bountiful.automaticallyGiveup", "orange");
      cancel_bounty(b.type); // automatically give up if unaccessible
    }
    return false;
  }

  // refresh BHH information
  visit_bhh();
  return true;
}

// @Overload
boolean hunt_bounty(string b) {
  return hunt_bounty(_bounty(b));
}

//----------------------------------------
// Combat Functions

// TODO: Consolidate using a record for banishers
monster[item] get_used_item_banishers(location loc) {
  // Banished monster data is stored in the format by mafia:
  // monster1:item1:turn_used1:monster2:item2:turn_used2:etc...
  // TODO/BUG: Sometimes this property isn't updated?
  string[int] banish_data = get_property("banishedMonsters").split_string(":");

  monster[item] list;
  for(int i = 1; i < banish_data.count(); i += 3) {
    monster m = to_monster(banish_data[i - 1]);
    int[monster] invert;
    foreach id, em in get_monsters(loc) {
      invert[em] = id;
    }
    item it = to_item(banish_data[i]);
    if(invert contains m && it.combat) list[it] = m;
  }

  return list;
}

item get_unused_item_banisher(location loc) {
  monster[item] used = get_used_item_banishers(loc);

  foreach banisher in BAN_ITEMS {
    if(mall_price(banisher) > maxBanish) {
      print("Not using banisher " + banisher.to_string() + "as it is too expensive. Value > maxBanishCost preference", "red");
      continue;
    }
    if(!(used contains banisher)) {
      return banisher;
    }
  }

  return $item[none];
}

monster[skill] get_used_skill_banishers(location loc) {
  // Banished monster data is stored in the format by mafia:
  // monster1:item1:turn_used1:monster2:item2:turn_used2:etc...
  string[int] banish_data = get_property("banishedMonsters").split_string(":");

  monster[skill] list;
  for(int i = 1; i < banish_data.count(); i += 3) {
    monster m = to_monster(banish_data[i - 1]);
    int[monster] invert;
    foreach id, em in get_monsters(loc) {
      invert[em] = id;
    }

    skill sk;
    // Special case handling
    if(banish_data[i] == "pantsgiving") {
      sk = $skill[Talk About Politics];
    } else {
      sk = to_skill(banish_data[i]);
    }
    if(invert contains m && sk.combat) list[sk] = m;
  }

  return list;
}

skill get_unused_skill_banisher(location loc) {
  monster[skill] used = get_used_skill_banishers(loc);

  // Snokebomb from Snojo IOTM
  skill banisher = $skill[Snokebomb];
  if(!(used contains banisher) && have_skill(banisher) && my_mp() >= mp_cost(banisher) && get_property("_snokebombUsed").to_int() < 3)
  {
    print("Snokebomb on this one!", "blue");
    return banisher;
  }

  // Talk About Politics from Pantsgiving IOTM
  banisher = $skill[Talk About Politics];
  if(!(used contains banisher) && have_skill(banisher) && my_mp() >= mp_cost(banisher) && get_property("_pantsgivingBanish").to_int() < 5)
  {
    print("Talk About Politics on this one!", "blue");
    return banisher;
  }

  // Cosmic Bowling Ball IOTM
  banisher = $skill[Bowl a Curveball];
  if(!(used contains banisher) && have_skill(banisher))
  {
    print("Bowl a Curveball on this one!", "blue");
    return banisher;
  }

  // Curse of Vacation from Avatar of Ed path
  banisher = $skill[Curse of Vacation];
  if(!(used contains banisher) && have_skill(banisher) && my_mp() >= mp_cost(banisher))
  {
    print("Curse of Vacation on this one!", "blue");
    return banisher;
  }

  // System Sweep from Avatar of Grey You path
  banisher = $skill[System Sweep];
  if(!(used contains banisher) && have_skill(banisher) && my_mp() >= mp_cost(banisher))
  {
    print("System Sweep on this one!", "blue");
    return banisher;
  }

  // Punt from being a Pig Skinner if Shadows over Loathing
  banisher = $skill[Punt];
  if(!(used contains banisher) && have_skill(banisher) && my_mp() >= mp_cost(banisher))
  {
    print("Punt on this one!", "blue");
    return banisher;
  }

  // Batter Up! from being a Seal Clubber
  banisher = $skill[Batter Up!];
  // stolen from autoscend
  boolean hasClubEquipped()
  {
    return item_type(equipped_item($slot[weapon])) == "club" || (item_type(equipped_item($slot[weapon])) == "sword" && have_effect($effect[iron palms]) > 0);
  }
  if(!(used contains banisher) && have_skill(banisher) && my_fury() >= 5 && hasClubEquipped())
  {
    print("Batter Up! on this one!", "blue");
    return banisher;
  }

  return $skill[none];
}

/**
* Custom action filter, see here: http://wiki.kolmafia.us/index.php?title=Adventure
* Behavior includes:
*  - Copying bounty targets if bountiful.useCopier is true
*  - Banishing non-bounty targets if bountiful.useBanisher is true and the monster
*    is banishable
*  - (Unimplemented) free runaway from non-bounty targets if bountiful.useRunaway
*    is true
*  - Does CCS action otherwise
* @param {int} round   - the current combat round
* @param {monster} opp - the current enemy monster
* @param {string} text - the current page text
* @returns {boolean} - if the given monster is being hunted
*/
string combat(int round, monster opp, string text) {
  // Check if the current monster is hunted
  if(is_hunted(opp)) {
    if(round == 0) print("Hey it's the bounty monster!", "blue");

    // add more copies of the bounty to the combat queue
    if(addBountyToQueue(opp, true) != "") {
      return addBountyToQueue(opp, false);
    }
    
    // Copy at the beginning of the fight if possible
    // TODO: Fix my_location() not working with copies (putty, etc)
    if(useCopier && (round == 0) && (_remaining(current) > 1)) {
      int doh_copies = get_property("_raindohCopiesMade").to_int();
      int putty_copies = get_property("spookyPuttyCopiesMade").to_int();

      if((doh_copies + putty_copies) < copies_available()) {
        if((item_amount($item[Rain-Doh black box]) > 0) &&
           (doh_copies < 5)) {
          return "item Rain-Doh black box";
        } else if(item_amount($item[Spooky Putty sheet]) > 0 &&
                 (putty_copies < 5)) {
          return "item Spooky Putty sheet";
        }
      }
    // Free kill if we're doing that
    } else if(useKill && item_amount($item[Power pill]) > 1 &&
              get_property("_powerPillUses").to_int() < 20) {
      return "item power pill";
    }
  } else {

    // Ban logic
    if(useBan && can_banish(my_location()) && !($monsters[blackberry bush,screambat,Smut orc pervert] contains opp)) {
      // Prefer skill banishes over items (they're free)
      skill skill_banisher = get_unused_skill_banisher(my_location());
      if(skill_banisher != $skill[none]) {
        print("Going to banish with skill " + skill_banisher.to_string());
        return "skill " + to_string(skill_banisher);
      }

      item item_banisher = get_unused_item_banisher(my_location());

      // This should never happen but Mafia seems to occasionally not keep track
      // of banishes for some reason - TODO: Figure this out
      // BUG: This debugging code introduces a bug...
      /*
      if(LAST_BANISH == item_banisher && LAST_LOCATION == my_location()) {
        abort("Script picked the same banisher (" + LAST_BANISH.to_string() +
              ") twice in a row for the same location (" + LAST_LOCATION.to_string() + ")");
      }
      */

      if(item_amount(item_banisher) > 0) {
        // For debugging: see above comment
        LAST_BANISH = item_banisher;
        LAST_LOCATION = my_location();

        return "item " + to_string(item_banisher);
      }
    }
    if(useRun) {
      // Use familiar run away
      if(my_familiar() == $familiar[Pair of Stomping Boots] ||
        (my_familiar() == $familiar[Frumious Bandersnatch] &&
          have_effect($effect[Ode to Booze]) > 0)) {

        // Yucky nested if statement
        if(get_property("_banderRunaways").to_int() < round(numeric_modifier("Familiar Weight")) / 5) {
          return "run away";
        }
      }
    }
  }

  // Kill monster by attacking. Assuming we are sufficiently over leveled
  print("Simply attacking");
  return "attack";
}

//----------------------------------------
// Main Function

void main(string params) {
  string[int] args = split_string(params, " ");
  string doWhat = args[0];
  int arglen = count(args);

  // Command handling
  switch(doWhat) {
    case 'hunt':
      if(arglen > 1) {
        visit_bhh(); // refresh BHH status
        switch(args[1]) {
          // This will accept *ALL* easy/hard/special bounties
          // ie. if you have an easy from a previous day, it will do that one,
          // as well as the easy for the current day
          case 'easy':
            print("Hunting easy bounty!", "blue");

            set_property("choiceAdventure113",2);	// Knob Goblin BBQ
            set_property("choiceAdventure502",2);	// Arboreal Respite
            set_property("choiceAdventure505",2);	// Consciousness of a Stream
            set_property("choiceAdventure1062",3);	// Lots of Options
            set_property("choiceAdventure1060",3);	// Temporarily Out of Skeletons. Get mus substate

            while(_bounty(EASY) != $bounty[none] && my_adventures() > 0) {
              if(!hunt_bounty(_bounty(EASY))) break;
            }
            break;
          case 'hard':
            print("Hunting hard bounty!", "blue");

            set_property("choiceAdventure669",1);	// The Fast and the Furry-ous
            set_property("choiceAdventure670",4);	// You Don't Mess Around with Gym
            set_property("choiceAdventure671",4);	// Out in the Open Source
            set_property("choiceAdventure675",4);	// Melon Collie and the Infinite Lameness
            set_property("choiceAdventure676",1);	// Flavor of a Raver
            set_property("choiceAdventure677",2);	// Copper Feel
            set_property("choiceAdventure678",4);	// Yeah, You're for Me, Punk Rock Giant
            set_property("choiceAdventure786",3);	// Working Holiday
            set_property("choiceAdventure923",1);	// The Black Forest
            set_property("choiceAdventure924",1);	// You Found Your Thrill

            while(_bounty(HARD) != $bounty[none] && my_adventures() > 0) {
              if(!hunt_bounty(_bounty(HARD))) break;
            }
            break;
          case 'special':
            print("Hunting special bounty!", "blue");

            set_property("choiceAdventure276",2);	// The Gong Has Been Bung

            while(_bounty(SPECIAL) != $bounty[none] && my_adventures() > 0) {
              if(!hunt_bounty(_bounty(SPECIAL))) break;
            }
            break;
          case 'optimal':
          case 'fastest':
          case 'best':
            print("Hunting optimal bounty!", "blue");
            bounty b = optimal_bounty();
            while(_bounty(b.type) != $bounty[none] && my_adventures() > 0) {
              if(!hunt_bounty(b)) break;
            }
            break;
          case 'all':
            print("Hunting all bounties!", "blue");
            // Originally looped on optimal_bounty()
            // However if one didn't finish, like unlocker is too expensive, 
            // it would break and prevent remaining bounties from being hunted
            while(_bounty(EASY) != $bounty[none] && my_adventures() > 0) {
              if(!hunt_bounty(_bounty(EASY))) break;
            }
            while(_bounty(HARD) != $bounty[none] && my_adventures() > 0) {
              if(!hunt_bounty(_bounty(HARD))) break;
            }
            while(_bounty(SPECIAL) != $bounty[none] && my_adventures() > 0) {
              if(!hunt_bounty(_bounty(SPECIAL))) break;
            }
            break;
          default:
            print("Invalid bounty type!", "red");
        }
        // remove effects which can impact future adventuring
        if(have_effect($effect[half-astral]) > 0)
          cli_execute("shrug half-astral");
        if(my_adventures() == 0) print("Ran out of adventures!", "red");
      } else {
        print("No bounty type given!", "red");
      }
      break;
    default:
      print("Invalid command!", "red");
  }
}
