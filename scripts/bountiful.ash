/******************************************************************************
* Bountiful by RESPRiT
* Version 0.1
* https://github.com/RESPRiT
*
* Adapted from AutoBHH:
* -Originally by izchak
* -Major revisions by Raorn and Zarqon
******************************************************************************/
script "Bountiful";
notify tamedtheturtle;
since r18000;
import <canadv.ash>;

/****************************
Custom Properties Used:
 - bountiful.useBanisher
 - bountiful.useCopier
 - bountiful.useFax
 - bountiful.useRunaway
 - bountiful.maxBanishCost
 - bountiful.maxSpecialCost
*****************************/

//----------------------------------------
// Global Variables
string current;
int count;

// Property Shorthands:
//   Simply assigns property values to short variable names
boolean useBan = get_property("bountiful.useBanisher").to_boolean();
boolean useCopier = get_property("bountiful.useCopier").to_boolean();
boolean useFax = get_property("bountiful.useFax").to_boolean();
boolean useRun = get_property("bountiful.useRunaway").to_boolean();
int maxBanish = get_property("bountiful.maxBanishCost").to_int();
  if(maxBanish == 0) maxBanish = 1000000000;
int maxSpecial = get_property("bountiful.maxSpecialCost").to_int();
  if(maxSpecial == 0) maxSpecial = get_property("autoBuyPriceLimit ").to_int();

// Constants
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

boolean[skill] BAN_SKILLS = {
  $skill[Snokebomb] : true,
  $skill[Talk About Politics] : true
};

// Unlockers
item[location] CONTENT_ITEMS = {
  $location[Anger Man's Level] : $item[jar of psychoses (The Crackpot Mystic)],
  $location[Pirates of the Garbage Barges] : $item[one-day ticket to Dinseylandfill],
  $location[the Ice Hotel] : $item[one-day ticket to The Glaciest],
  $location[The Stately Pleasure Dome] : $item[tiny bottle of absinthe],
  $location[Domed City of Grimacia] : $item[transporter transponder],
  $location[LavaCo&trade; Lamp Factory] : $item[one-day ticket to That 70s Volcano],
  $location[The Clumsiness Grove] : $item[devilish folio],
  $location[The Nightmare Meatrealm] : $item[jar of psychoses (The Meatsmith)],
  $location[Sloppy Seconds Diner] : $item[one-day ticket to Spring Break Beach],
  $location[An Incredibly Strange Place (Bad Trip)] : $item[astral mushroom],
  $location[the Red Queen's Garden] : $item[&quot;DRINK ME&quot; potion],
  $location[Mt. Molehill] : $item[llama lama gong],
  $location[The Jungles of Ancient Loathing] : $item[empty agua de vida bottle],
  $location[Chinatown Shops] : $item[jar of psychoses (The Suspicious-Looking Guy)],
  $location[the Secret Government Laboratory] : $item[one-day ticket to Conspiracy Island]
};

//----------------------------------------
// Private Bounty Functions

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

boolean _accepted(string type) {
  switch(type) {
    case EASY:
      return get_property("currentEasyBountyItem") != "";
    case HARD:
      return get_property("currentHardBountyItem") != "";
    case SPECIAL:
      return get_property("currentSpecialBountyItem") != "";
    default:
      abort("_accepted: Invalid bounty type");
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
* @returns {int} - Returns the bounty item count if the type is accepted, or
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
      return -1;
    }
  } else {
    return -888;
  }
}

int _remaining(string type) {
  int count = _count(type);
  int total = _bounty(type).number;

  if(count >= 0) {
    return total - count;
  } else {
    return count;
  }
}

//----------------------------------------
// Helper Functions

// cute logic to calculate copiers per day
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

boolean buy_banishers() {
  int count = 0;

  foreach banisher in BAN_ITEMS {
    if(item_amount(banisher) < 1) {
      count += buy(1, banisher, maxBanish);
    }
  }

  return count > 0;
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

boolean accept_bounty(string type) {
  if(_accepted(type)) {
    return false;
  }

  string query = "&action=take"+_bounty(type).kol_internal_type;
  visit_bhh(query);
  visit_bhh();
  return true;
}

// @Overload
boolean accept_bounty(bounty b) {
  return accept_bounty(b.type);
}

// TODO
void print_current() {

}

// TODO
void print_available() {

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

boolean hunt_bounty(bounty b) {
  accept_bounty(b.type); // doesn't do anything if already accepted

  // use fax if that's what we're doing
  if(useFax && !to_boolean(get_property("_photocopyUsed"))) {
    faxbot(_bounty(b.type).monster);
    use(1, $item[photocopied monster]);
  // use copy if that's what we're doing
  } else if(item_amount($item[Rain-Doh box full of monster]) > 0 &&
            to_monster(get_property("rainDohMonster")) == b.monster) {
    use(1, $item[Rain-Doh box full of monster]);
  } else if(item_amount($item[Spooky Putty monster]) > 0 &&
            to_monster(get_property("spookyPuttyMonster")) == b.monster) {
    use(1, $item[Spooky Putty monster]);
  // if location is avilable or affordable, adventure
  } else if(can_adv(b.location, false) ||
            (b.type == SPECIAL &&
            mall_price(CONTENT_ITEMS[b.location]) <= maxSpecial)) {
    current = b.type;
    adventure(1, b.location, "combat");
  } else {
    // turns out we're doing nothing
    visit_bhh(); // refreshing because ??
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

// TODO: Only items, needs skills
monster[item] get_used_item_banishers() {
  // Banished monster data is stored in the format by mafia:
  // monster1:item1:turn_used1:monster2:item2:turn_used2:etc...
  string[int] banish_data = get_property("banishedMonsters").split_string(":");

  monster[item] list;
  for(int i = 0; i < banish_data.count(); i += 3) {
    monster m = to_monster(banish_data[i]);
    int[monster] invert;
    foreach id, em in get_monsters(_bounty(current).location) {
      invert[em] = id;
    }
    item it = to_item(banish_data[i + 1]);
    if(invert contains m && it.combat) list[it] = m;
  }

  return list;
}

item get_unused_item_banisher() {
  monster[item] used = get_used_item_banishers();

  foreach banisher in BAN_ITEMS {
    if(!(used contains banisher)) {
      return banisher;
    }
  }

  return $item[none];
}

monster[skill] get_used_skill_banishers() {
  // Banished monster data is stored in the format by mafia:
  // monster1:item1:turn_used1:monster2:item2:turn_used2:etc...
  string[int] banish_data = get_property("banishedMonsters").split_string(":");

  monster[skill] list;
  for(int i = 0; i < banish_data.count(); i += 3) {
    monster m = to_monster(banish_data[i]);
    int[monster] invert;
    foreach id, em in get_monsters(_bounty(current).location) {
      invert[em] = id;
    }
    skill sk = to_skill(banish_data[i + 1]);
    if(invert contains m && sk.combat) list[sk] = m;
  }

  return list;
}

skill get_unused_skill_banisher() {
  monster[skill] used = get_used_skill_banishers();

  foreach banisher in BAN_SKILLS {
    if(!(used contains banisher)) {
      return banisher;
    }
  }

  return $skill[none];
}

/**
* Custom action filter, see here:
*   http://wiki.kolmafia.us/index.php?title=Adventure
* @param {int} round   - the current combat round
* @param {monster} opp - the current enemy monster
* @param {string} text - the current page text
* @returns {boolean} - if the given monster is being hunted
*/
string combat(int round, monster opp, string text) {
  // Check if the current monster is hunted
  if(is_hunted(opp)) {
    // Copy round 1 if can
    // current wouldn't be needed if there was a to_bounty(monster m),
    // maybe I'll make one
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
    }
    // Ban logic
  } else if(useBan) {
    skill skill_banisher = get_unused_skill_banisher();
    if(have_skill(skill_banisher)) {
      return "cast " + to_string(skill_banisher);
    }

    item item_banisher = get_unused_item_banisher();
    if(item_amount(item_banisher) > 0) {
      return "item " + to_string(item_banisher);
    }
  } else if(useRun) {
    // TODO: runaway logic
  }

  // Default to CCS if custom actions can't happen
  return get_ccs_action(round);
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
      if(arglen > 2) {
        switch(args[1]) {
          // This will accept *ALL* easy/hard/special bounties
          // ie. if you have an easy from a previous day, it will do that one,
          // as well as the easy for the current day
          case 'easy':
            while(_bounty(EASY) != $bounty[none]) {
              if(!hunt_bounty(_bounty(EASY))) break;
            }
            break;
          case 'hard':
            while(_bounty(HARD) != $bounty[none]) {
              if(!hunt_bounty(_bounty(HARD))) break;
            }
            break;
          case 'special':
            while(_bounty(SPECIAL) != $bounty[none]) {
              if(!hunt_bounty(_bounty(SPECIAL))) break;
            }
            break;
          case 'optimal':
          case 'fastest':
          case 'best':
            bounty b = optimal_bounty();
            while(_bounty(b.type) != $bounty[none]) {
              if(!hunt_bounty(b)) break;
            }
            break;
          case 'all':
            while(optimal_bounty() != $bounty[none]) {
              if(!hunt_bounty(optimal_bounty())) break;
            }
            break;
          default:
            print("Invalid bounty type!", "red");
        }
      } else {
        print("No bounty type given!", "red");
      }
      break;
    case 'list':
      print_current();
      print_available();
      break;
    default:
      print("Invalid command!", "red");
  }
}
