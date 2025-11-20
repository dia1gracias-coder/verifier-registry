const minTonsForStorage: Int = ton("0.02");
const gasConsumption: Int = ton("0.02");

trait Rarity {
    const RARITY_BRONZE: String = "Bronze";
    const RARITY_SILVER: String = "Silver";
    const RARITY_GOLD: String = "Gold";
    const RARITY_PLATINUM: String = "Platinum";
    const RARITY_DIAMOND: String = "Diamond";
    const RARITY_OPALESCENT: String = "Opalescent";

  // Calculate rarity based on collector points
    virtual inline fun calculateRarity(points: Int): String {
        if (points >= 2501) {
            return self.RARITY_OPALESCENT;
        } else if (points >= 1001) {
            return self.RARITY_DIAMOND;
        } else if (points >= 451) {
            return self.RARITY_PLATINUM;
        } else if (points >= 151) {
            return self.RARITY_GOLD;
        } else if (points >= 41) {
            return self.RARITY_SILVER;
        } else {
            return self.RARITY_BRONZE;
        }
    }
}