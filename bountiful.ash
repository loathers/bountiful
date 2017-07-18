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

/****************************
Custom Properties Used:
 - bountiful.useBanisher
 - bountiful.useSpookyPutty
 - bountiful.useRainDoh
 - bountiful.useFax
 - bountiful.maxBanishCost
 - bountiful.maxSpecialCost
*****************************/

//----------------------------------------
// Global Variables

bounty[int] options; // Available bounties
bounty[int] current; // Active bounties

//----------------------------------------
// bounty.ash Functions

// Returns
string bstring(int n) {
   return (options contains n) ? options[n].number+" "+options[n].plural+" from "+options[n].monster : "";
}

//
string cstring(int n) {
   return (current contains n) ? current[n].number+" "+current[n].plural+" from "+current[n].monster : "";
}

boolean update_bounty() {
  return false;
}


boolean hunt_bounty() {
  return false;
}

/**
* Checks if the given monster is currently being hunted
* @param {string} opp - the string representation of the monster to check
* @returns {boolean} - if the given monster is being hunted
*/
boolean is_hunted(string opp) {
  monster m = to_monster(opp);
  int[item] drops = item_drops(m);
  boolean isTarget = drops contains to_item(get_property("currentEasyBountyItem")) ||
                     drops contains to_item(get_property("currentHardBountyItem")) ||
                     drops contains to_item(get_property("currentSpecialBountyItem"));
}

// Custom combat function
string combatBounty(int round, string opp, string text) {
  if(is_hunted(opp)) {

  } else {
    // Default to CCS if the monster is not being hunted
    return get_ccs_action(round);
  }

  return "";
}

// Main function execution
void main(string params) {

}
