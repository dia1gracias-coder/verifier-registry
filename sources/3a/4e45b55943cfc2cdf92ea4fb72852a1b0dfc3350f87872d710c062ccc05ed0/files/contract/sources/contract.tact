import "@stdlib/deploy";
import "@stdlib/ownable";

message FundPayout{
  value: Int as coins;
}

message GamePayoutSlim{
  value: Int as coins;
  rows: Int;
  risks: Int;
}

struct GamePayoutSlimResponse {
  winAmount: Int;
  winMultipler: Int;
  lastPathIdx: Int;
  rows: Int;
  risks: Int;
}

message MultiGamePayoutSlim{
  valuePerIteration: Int as coins;
  iterations: Int;
  rows: Int;
  risks: Int;
}

struct MultiGamePayoutSlimResponse {
  winTotalAmount: Int;
  winAmount: map<Int, Int>;
  winMultipler: map<Int, Int>;
  lastPathIdx: map<Int, Int>;
  iterationCount: Int;
}

struct PathInfo {
  path: map<Int, Int>;
  path_count: Int;
}

message Withdraw {
  amount: Int as coins;
}

struct SlotInfo {
  slot: map<Int, Int>;
  slot_count: Int;
}

struct SlotRisk {
  slot_risk: map<Int, SlotInfo>;
  slot_risk_count: Int;
}

struct SlotUniverse {
  slots: map<Int, SlotRisk>;
  slots_count: Int;
}

contract AlpaTonPlinko with Deployable, Ownable {

  //odds: https://wizardofodds.com/games/plinko/

  slot_universe: SlotUniverse; 

  owner: Address;
  const MinTonForStorage: Int = ton("0.01");
 
  init(owner: Address) {

    self.owner = owner;
    self.slot_universe = SlotUniverse {
      slots: emptyMap(),
      slots_count: 9,
    };

    self.initOdd8rows();
    self.initOdd9rows();
    self.initOdd10rows();
    self.initOdd11rows();
    self.initOdd12rows();
    self.initOdd13rows();
    self.initOdd14rows();
    self.initOdd15rows();
    self.initOdd16rows();

  }

  fun initOdd8rows() {

    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 9,
    };

    // 8 rows odds
    slotinfo_low.slot.set(0, 56);
    slotinfo_low.slot.set(1, 21);
    slotinfo_low.slot.set(2, 11);
    slotinfo_low.slot.set(3, 10);
    slotinfo_low.slot.set(4, 5);
    slotinfo_low.slot.set(5, 10);
    slotinfo_low.slot.set(6, 11);
    slotinfo_low.slot.set(7, 21);
    slotinfo_low.slot.set(8, 56);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 9,
    };

    slotinfo_medium.slot.set(0, 130);
    slotinfo_medium.slot.set(1, 30);
    slotinfo_medium.slot.set(2, 13);
    slotinfo_medium.slot.set(3, 7);
    slotinfo_medium.slot.set(4, 4);
    slotinfo_medium.slot.set(5, 7);
    slotinfo_medium.slot.set(6, 13);
    slotinfo_medium.slot.set(7, 30);
    slotinfo_medium.slot.set(8, 130);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 9,
    };

    slotinfo_high.slot.set(0, 290);
    slotinfo_high.slot.set(1, 40);
    slotinfo_high.slot.set(2, 15);
    slotinfo_high.slot.set(3, 3);
    slotinfo_high.slot.set(4, 2);
    slotinfo_high.slot.set(5, 3);
    slotinfo_high.slot.set(6, 15);
    slotinfo_high.slot.set(7, 40);
    slotinfo_high.slot.set(8, 290);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(8, slotrisk);

  }

  fun initOdd9rows() {

    // 9 rows odds
    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 10,
    };

    slotinfo_low.slot.set(0, 56);
    slotinfo_low.slot.set(1, 20);
    slotinfo_low.slot.set(2, 16);
    slotinfo_low.slot.set(3, 10);
    slotinfo_low.slot.set(4, 7);
    slotinfo_low.slot.set(5, 7);
    slotinfo_low.slot.set(6, 10);
    slotinfo_low.slot.set(7, 16);
    slotinfo_low.slot.set(8, 20);
    slotinfo_low.slot.set(9, 56);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 10,
    };

    slotinfo_medium.slot.set(0, 180);
    slotinfo_medium.slot.set(1, 40);
    slotinfo_medium.slot.set(2, 17);
    slotinfo_medium.slot.set(3, 9);
    slotinfo_medium.slot.set(4, 5);
    slotinfo_medium.slot.set(5, 5);
    slotinfo_medium.slot.set(6, 9);
    slotinfo_medium.slot.set(7, 17);
    slotinfo_medium.slot.set(8, 40);
    slotinfo_medium.slot.set(9, 180);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 10,
    };

    slotinfo_high.slot.set(0, 430);
    slotinfo_high.slot.set(1, 70);
    slotinfo_high.slot.set(2, 20);
    slotinfo_high.slot.set(3, 6);
    slotinfo_high.slot.set(4, 2);
    slotinfo_high.slot.set(5, 2);
    slotinfo_high.slot.set(6, 6);
    slotinfo_high.slot.set(7, 20);
    slotinfo_high.slot.set(8, 70);
    slotinfo_high.slot.set(9, 430);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(9, slotrisk);

  }

  fun initOdd10rows() {

    // 10 rows odds

    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 11,
    };

    slotinfo_low.slot.set(0, 89);
    slotinfo_low.slot.set(1, 30);
    slotinfo_low.slot.set(2, 14);
    slotinfo_low.slot.set(3, 11);
    slotinfo_low.slot.set(4, 10);
    slotinfo_low.slot.set(5, 5);
    slotinfo_low.slot.set(6, 10);
    slotinfo_low.slot.set(7, 11);
    slotinfo_low.slot.set(8, 14);
    slotinfo_low.slot.set(9, 30);
    slotinfo_low.slot.set(10, 89);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 11,
    };

    slotinfo_medium.slot.set(0, 220);
    slotinfo_medium.slot.set(1, 50);
    slotinfo_medium.slot.set(2, 20);
    slotinfo_medium.slot.set(3, 14);
    slotinfo_medium.slot.set(4, 6);
    slotinfo_medium.slot.set(5, 4);
    slotinfo_medium.slot.set(6, 6);
    slotinfo_medium.slot.set(7, 14);
    slotinfo_medium.slot.set(8, 20);
    slotinfo_medium.slot.set(9, 50);
    slotinfo_medium.slot.set(10, 220);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 11,
    };

    slotinfo_high.slot.set(0, 760);
    slotinfo_high.slot.set(1, 100);
    slotinfo_high.slot.set(2, 30);
    slotinfo_high.slot.set(3, 9);
    slotinfo_high.slot.set(4, 3);
    slotinfo_high.slot.set(5, 2);
    slotinfo_high.slot.set(6, 3);
    slotinfo_high.slot.set(7, 9);
    slotinfo_high.slot.set(8, 3);
    slotinfo_high.slot.set(9, 100);
    slotinfo_high.slot.set(10, 760);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(10, slotrisk);

  }

  fun initOdd11rows() {

    // 11 rows odds

    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 12,
    };

    slotinfo_low.slot.set(0, 84);
    slotinfo_low.slot.set(1, 30);
    slotinfo_low.slot.set(2, 19);
    slotinfo_low.slot.set(3, 13);
    slotinfo_low.slot.set(4, 10);
    slotinfo_low.slot.set(5, 7);
    slotinfo_low.slot.set(6, 7);
    slotinfo_low.slot.set(7, 10);
    slotinfo_low.slot.set(8, 13);
    slotinfo_low.slot.set(9, 19);
    slotinfo_low.slot.set(10, 30);
    slotinfo_low.slot.set(11, 84);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 12,
    };

    slotinfo_medium.slot.set(0, 240);
    slotinfo_medium.slot.set(1, 60);
    slotinfo_medium.slot.set(2, 30);
    slotinfo_medium.slot.set(3, 18);
    slotinfo_medium.slot.set(4, 7);
    slotinfo_medium.slot.set(5, 5);
    slotinfo_medium.slot.set(6, 5);
    slotinfo_medium.slot.set(7, 7);
    slotinfo_medium.slot.set(8, 18);
    slotinfo_medium.slot.set(9, 30);
    slotinfo_medium.slot.set(10, 60);
    slotinfo_medium.slot.set(11, 240);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 12,
    };

    slotinfo_high.slot.set(0, 1200);
    slotinfo_high.slot.set(1, 140);
    slotinfo_high.slot.set(2, 52);
    slotinfo_high.slot.set(3, 14);
    slotinfo_high.slot.set(4, 4);
    slotinfo_high.slot.set(5, 2);
    slotinfo_high.slot.set(6, 2);
    slotinfo_high.slot.set(7, 4);
    slotinfo_high.slot.set(8, 14);
    slotinfo_high.slot.set(9, 52);
    slotinfo_high.slot.set(10, 140);
    slotinfo_high.slot.set(11, 1200);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(11, slotrisk);

  }

  fun initOdd12rows() {

    // 12 rows odds
    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 13,
    };

    slotinfo_low.slot.set(0, 100);
    slotinfo_low.slot.set(1, 30);
    slotinfo_low.slot.set(2, 16);
    slotinfo_low.slot.set(3, 14);
    slotinfo_low.slot.set(4, 11);
    slotinfo_low.slot.set(5, 10);
    slotinfo_low.slot.set(6, 5);
    slotinfo_low.slot.set(7, 10);
    slotinfo_low.slot.set(8, 11);
    slotinfo_low.slot.set(9, 14);
    slotinfo_low.slot.set(10, 16);
    slotinfo_low.slot.set(11, 30);
    slotinfo_low.slot.set(12, 100);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 13,
    };

    slotinfo_medium.slot.set(0, 330);
    slotinfo_medium.slot.set(1, 110);
    slotinfo_medium.slot.set(2, 40);
    slotinfo_medium.slot.set(3, 20);
    slotinfo_medium.slot.set(4, 11);
    slotinfo_medium.slot.set(5, 6);
    slotinfo_medium.slot.set(6, 3);
    slotinfo_medium.slot.set(7, 6);
    slotinfo_medium.slot.set(8, 11);
    slotinfo_medium.slot.set(9, 20);
    slotinfo_medium.slot.set(10, 40);
    slotinfo_medium.slot.set(11, 110);
    slotinfo_medium.slot.set(12, 330);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 13,
    };

    slotinfo_high.slot.set(0, 1700);
    slotinfo_high.slot.set(1, 240);
    slotinfo_high.slot.set(2, 81);
    slotinfo_high.slot.set(3, 20);
    slotinfo_high.slot.set(4, 7);
    slotinfo_high.slot.set(5, 2);
    slotinfo_high.slot.set(6, 2);
    slotinfo_high.slot.set(7, 2);
    slotinfo_high.slot.set(8, 7);
    slotinfo_high.slot.set(9, 20);
    slotinfo_high.slot.set(10, 81);
    slotinfo_high.slot.set(11, 240);
    slotinfo_high.slot.set(12, 1700);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(12, slotrisk);

  }

  fun initOdd13rows() {

    // 13 rows odds

    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 14,
    };

    slotinfo_low.slot.set(0, 81);
    slotinfo_low.slot.set(1, 40);
    slotinfo_low.slot.set(2, 30);
    slotinfo_low.slot.set(3, 19);
    slotinfo_low.slot.set(4, 12);
    slotinfo_low.slot.set(5, 9);
    slotinfo_low.slot.set(6, 7);
    slotinfo_low.slot.set(7, 7);
    slotinfo_low.slot.set(8, 9);
    slotinfo_low.slot.set(9, 12);
    slotinfo_low.slot.set(10, 19);
    slotinfo_low.slot.set(11, 3);
    slotinfo_low.slot.set(12, 4);
    slotinfo_low.slot.set(13, 81);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 14,
    };

    slotinfo_medium.slot.set(0, 430);
    slotinfo_medium.slot.set(1, 130);
    slotinfo_medium.slot.set(2, 60);
    slotinfo_medium.slot.set(3, 30);
    slotinfo_medium.slot.set(4, 13);
    slotinfo_medium.slot.set(5, 7);
    slotinfo_medium.slot.set(6, 4);
    slotinfo_medium.slot.set(7, 4);
    slotinfo_medium.slot.set(8, 7);
    slotinfo_medium.slot.set(9, 13);
    slotinfo_medium.slot.set(10, 30);
    slotinfo_medium.slot.set(11, 60);
    slotinfo_medium.slot.set(12, 130);
    slotinfo_medium.slot.set(13, 430);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 14,
    };

    slotinfo_high.slot.set(0, 2600);
    slotinfo_high.slot.set(1, 370);
    slotinfo_high.slot.set(2, 110);
    slotinfo_high.slot.set(3, 40);
    slotinfo_high.slot.set(4, 10);
    slotinfo_high.slot.set(5, 2);
    slotinfo_high.slot.set(6, 2);
    slotinfo_high.slot.set(7, 2);
    slotinfo_high.slot.set(8, 2);
    slotinfo_high.slot.set(9, 10);
    slotinfo_high.slot.set(10, 40);
    slotinfo_high.slot.set(11, 110);
    slotinfo_high.slot.set(12, 370);
    slotinfo_high.slot.set(13, 2600);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(13, slotrisk);

  }

  fun initOdd14rows() {

    // 14 rows odds

    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 14,
    };

    slotinfo_low.slot.set(0, 71);
    slotinfo_low.slot.set(1, 40);
    slotinfo_low.slot.set(2, 19);
    slotinfo_low.slot.set(3, 14);
    slotinfo_low.slot.set(4, 13);
    slotinfo_low.slot.set(5, 11);
    slotinfo_low.slot.set(6, 10);
    slotinfo_low.slot.set(7, 5);
    slotinfo_low.slot.set(8, 10);
    slotinfo_low.slot.set(9, 11);
    slotinfo_low.slot.set(10, 13);
    slotinfo_low.slot.set(11, 14);
    slotinfo_low.slot.set(12, 19);
    slotinfo_low.slot.set(13, 40);
    slotinfo_low.slot.set(14, 71);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 14,
    };

    slotinfo_medium.slot.set(0, 580);
    slotinfo_medium.slot.set(1, 150);
    slotinfo_medium.slot.set(2, 70);
    slotinfo_medium.slot.set(3, 40);
    slotinfo_medium.slot.set(4, 19);
    slotinfo_medium.slot.set(5, 10);
    slotinfo_medium.slot.set(6, 5);
    slotinfo_medium.slot.set(7, 2);
    slotinfo_medium.slot.set(8, 5);
    slotinfo_medium.slot.set(9, 10);
    slotinfo_medium.slot.set(10, 19);
    slotinfo_medium.slot.set(11, 40);
    slotinfo_medium.slot.set(12, 70);
    slotinfo_medium.slot.set(13, 150);
    slotinfo_medium.slot.set(14, 580);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 14,
    };

    slotinfo_high.slot.set(0, 4200);
    slotinfo_high.slot.set(1, 560);
    slotinfo_high.slot.set(2, 180);
    slotinfo_high.slot.set(3, 50);
    slotinfo_high.slot.set(4, 19);
    slotinfo_high.slot.set(5, 3);
    slotinfo_high.slot.set(6, 2);
    slotinfo_high.slot.set(7, 2);
    slotinfo_high.slot.set(8, 2);
    slotinfo_high.slot.set(9, 3);
    slotinfo_high.slot.set(10, 19);
    slotinfo_high.slot.set(11, 50);
    slotinfo_high.slot.set(12, 180);
    slotinfo_high.slot.set(13, 560);
    slotinfo_high.slot.set(14, 4200);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(14, slotrisk);

  }

  fun initOdd15rows() {

    // 15 rows odds

    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 15,
    };

    slotinfo_low.slot.set(0, 150);
    slotinfo_low.slot.set(1, 80);
    slotinfo_low.slot.set(2, 30);
    slotinfo_low.slot.set(3, 20);
    slotinfo_low.slot.set(4, 15);
    slotinfo_low.slot.set(5, 11);
    slotinfo_low.slot.set(6, 10);
    slotinfo_low.slot.set(7, 7);
    slotinfo_low.slot.set(8, 7);
    slotinfo_low.slot.set(9, 10);
    slotinfo_low.slot.set(10, 11);
    slotinfo_low.slot.set(11, 15);
    slotinfo_low.slot.set(12, 20);
    slotinfo_low.slot.set(13, 30);
    slotinfo_low.slot.set(14, 80);
    slotinfo_low.slot.set(15, 150);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 15,
    };

    slotinfo_medium.slot.set(0, 880);
    slotinfo_medium.slot.set(1, 180);
    slotinfo_medium.slot.set(2, 110);
    slotinfo_medium.slot.set(3, 50);
    slotinfo_medium.slot.set(4, 30);
    slotinfo_medium.slot.set(5, 13);
    slotinfo_medium.slot.set(6, 5);
    slotinfo_medium.slot.set(7, 3);
    slotinfo_medium.slot.set(8, 3);
    slotinfo_medium.slot.set(9, 5);
    slotinfo_medium.slot.set(10, 13);
    slotinfo_medium.slot.set(11, 30);
    slotinfo_medium.slot.set(12, 50);
    slotinfo_medium.slot.set(13, 110);
    slotinfo_medium.slot.set(14, 180);
    slotinfo_medium.slot.set(15, 880);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 15,
    };

    slotinfo_high.slot.set(0, 6200);
    slotinfo_high.slot.set(1, 830);
    slotinfo_high.slot.set(2, 270);
    slotinfo_high.slot.set(3, 80);
    slotinfo_high.slot.set(4, 30);
    slotinfo_high.slot.set(5, 5);
    slotinfo_high.slot.set(6, 2);
    slotinfo_high.slot.set(7, 2);
    slotinfo_high.slot.set(8, 2);
    slotinfo_high.slot.set(9, 2);
    slotinfo_high.slot.set(10, 5);
    slotinfo_high.slot.set(11, 30);
    slotinfo_high.slot.set(12, 80);
    slotinfo_high.slot.set(13, 270);
    slotinfo_high.slot.set(14, 830);
    slotinfo_high.slot.set(15, 6200);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(15, slotrisk);

  }

  fun initOdd16rows() {

    // 16 rows odds
    let slotinfo_low = SlotInfo {
      slot: emptyMap(),
      slot_count: 16,
    };

    slotinfo_low.slot.set(0, 160);
    slotinfo_low.slot.set(1, 90);
    slotinfo_low.slot.set(2, 20);
    slotinfo_low.slot.set(3, 14);
    slotinfo_low.slot.set(4, 14);
    slotinfo_low.slot.set(5, 12);
    slotinfo_low.slot.set(6, 11);
    slotinfo_low.slot.set(7, 10);
    slotinfo_low.slot.set(8, 5);
    slotinfo_low.slot.set(9, 10);
    slotinfo_low.slot.set(10, 11);
    slotinfo_low.slot.set(11, 12);
    slotinfo_low.slot.set(12, 14);
    slotinfo_low.slot.set(13, 14);
    slotinfo_low.slot.set(14, 20);
    slotinfo_low.slot.set(15, 90);
    slotinfo_low.slot.set(16, 160);

    let slotinfo_medium = SlotInfo {
      slot: emptyMap(),
      slot_count: 16,
    };

    slotinfo_medium.slot.set(0, 1100);
    slotinfo_medium.slot.set(1, 410);
    slotinfo_medium.slot.set(2, 100);
    slotinfo_medium.slot.set(3, 50);
    slotinfo_medium.slot.set(4, 30);
    slotinfo_medium.slot.set(5, 15);
    slotinfo_medium.slot.set(6, 10);
    slotinfo_medium.slot.set(7, 5);
    slotinfo_medium.slot.set(8, 3);
    slotinfo_medium.slot.set(9, 5);
    slotinfo_medium.slot.set(10, 10);
    slotinfo_medium.slot.set(11, 15);
    slotinfo_medium.slot.set(12, 30);
    slotinfo_medium.slot.set(13, 50);
    slotinfo_medium.slot.set(14, 100);
    slotinfo_medium.slot.set(15, 410);
    slotinfo_medium.slot.set(16, 1100);

    let slotinfo_high = SlotInfo {
      slot: emptyMap(),
      slot_count: 16,
    };

    slotinfo_high.slot.set(0, 10000);
    slotinfo_high.slot.set(1, 1300);
    slotinfo_high.slot.set(2, 260);
    slotinfo_high.slot.set(3, 90);
    slotinfo_high.slot.set(4, 40);
    slotinfo_high.slot.set(5, 20);
    slotinfo_high.slot.set(6, 2);
    slotinfo_high.slot.set(7, 2);
    slotinfo_high.slot.set(8, 2);
    slotinfo_high.slot.set(9, 2);
    slotinfo_high.slot.set(10, 2);
    slotinfo_high.slot.set(11, 20);
    slotinfo_high.slot.set(12, 40);
    slotinfo_high.slot.set(13, 90);
    slotinfo_high.slot.set(14, 260);
    slotinfo_high.slot.set(15, 1300);
    slotinfo_high.slot.set(16, 10000);

    let slotrisk = SlotRisk {
      slot_risk: emptyMap(),
      slot_risk_count: 3,
    };

    slotrisk.slot_risk.set(0, slotinfo_low);
    slotrisk.slot_risk.set(1, slotinfo_medium);
    slotrisk.slot_risk.set(2, slotinfo_high);

    self.slot_universe.slots.set(16, slotrisk);

  }
  
  fun getIndexFromOddRow16(ran: Int): Int {

    if (ran >= 0 && ran < 15) {
      return 0;
    } else if (ran >= 15 && ran < 259) {
      return 1;
    } else if (ran >= 259 && ran < 2090) {
      return 2;
    } else if (ran >= 2090 && ran < 10635) {
      return 3;
    } else if (ran >= 10635 && ran < 38406) {
      return 4;
    } else if (ran >= 38406 && ran < 105056) {
      return 5;
    } else if (ran >= 105056 && ran < 227248) {
      return 6;
    } else if (ran >= 227248 && ran < 401809) {
      return 7;
    } else if (ran >= 401809 && ran < 598191) {
      return 8;
    } else if (ran >= 598191 && ran < 772752) {
      return 9;
    } else if (ran >= 772752 && ran < 894944) {
      return 10;
    } else if (ran >= 894944 && ran < 961594) {
      return 11;
    } else if (ran >= 961594 && ran < 989365) {
      return 12;
    } else if (ran >= 989365 && ran < 997910) {
      return 13;
    } else if (ran >= 997910 && ran < 999741) {
      return 14;
    } else if (ran >= 999741 && ran < 999985) {
      return 15;
    } else if (ran >= 999985 && ran < 1000000) {
      return 16;
    }

    return 8;    
  }

  fun getIndexFromOddRow15(ran: Int): Int {

    if (ran >= 0 && ran < 31) {
      return 0;
    } else if (ran >= 31 && ran < 489) {
      return 1;
    } else if (ran >= 489 && ran < 3693) {
      return 2;
    } else if (ran >= 3693 && ran < 17578) {
      return 3;
    } else if (ran >= 17578 && ran < 59234) {
      return 4;
    } else if (ran >= 59234 && ran < 150878) {
      return 5;
    } else if (ran >= 150878 && ran < 303618) {
      return 6;
    } else if (ran >= 303618 && ran < 500000) {
      return 7;
    } else if (ran >= 500000 && ran < 696382) {
      return 8;
    } else if (ran >= 696382 && ran < 849122) {
      return 9;
    } else if (ran >= 849122 && ran < 940766) {
      return 10;
    } else if (ran >= 940766 && ran < 982422) {
      return 11;
    } else if (ran >= 982422 && ran < 996307) {
      return 12;
    } else if (ran >= 996307 && ran < 999511) {
      return 13;
    } else if (ran >= 999511 && ran < 999969) {
      return 14;
    } else if (ran >= 999969 && ran < 1000000) {
      return 15;
    }

    return 7;    
  }

  fun getIndexFromOddRow14(ran: Int): Int {

    if (ran >= 0 && ran < 61) {
      return 0;
    } else if (ran >= 61 && ran < 915) {
      return 1;
    } else if (ran >= 915 && ran < 6469) {
      return 2;
    } else if (ran >= 6469 && ran < 28686) {
      return 3;
    } else if (ran >= 28686 && ran < 89782) {
      return 4;
    } else if (ran >= 89782 && ran < 211974) {
      return 5;
    } else if (ran >= 211974 && ran < 395263) {
      return 6;
    } else if (ran >= 395263 && ran < 604737) {
      return 7;
    } else if (ran >= 604737 && ran < 788026) {
      return 8;
    } else if (ran >= 788026 && ran < 910218) {
      return 9;
    } else if (ran >= 910218 && ran < 971314) {
      return 10;
    } else if (ran >= 971314 && ran < 993531) {
      return 11;
    } else if (ran >= 993531 && ran < 999085) {
      return 12;
    } else if (ran >= 999085 && ran < 999939) {
      return 13;
    } else if (ran >= 999939 && ran < 1000000) {
      return 14;
    }

    return 7;    
  }

  fun getIndexFromOddRow13(ran: Int): Int {

    if (ran >= 0 && ran < 122) {
      return 0;
    } else if (ran >= 122 && ran < 1709) {
      return 1;
    } else if (ran >= 1709 && ran < 11230) {
      return 2;
    } else if (ran >= 11230 && ran < 46142) {
      return 3;
    } else if (ran >= 46142 && ran < 133422) {
      return 4;
    } else if (ran >= 133422 && ran < 290526) {
      return 5;
    } else if (ran >= 290526 && ran < 500000) {
      return 6;
    } else if (ran >= 500000 && ran < 709474) {
      return 7;
    } else if (ran >= 709474 && ran < 866578) {
      return 8;
    } else if (ran >= 866578 && ran < 953858) {
      return 9;
    } else if (ran >= 953858 && ran < 988770) {
      return 10;
    } else if (ran >= 988770 && ran < 998291) {
      return 11;
    } else if (ran >= 998291 && ran < 999878) {
      return 12;
    } else if (ran >= 999878 && ran < 1000000) {
      return 13;
    }

    return 6;    
  }

  fun getIndexFromOddRow12(ran: Int): Int {

    if (ran >= 0 && ran < 244) {
      return 0;
    } else if (ran >= 244 && ran < 3174) {
      return 1;
    } else if (ran >= 3174 && ran < 19287) {
      return 2;
    } else if (ran >= 19287 && ran < 72998) {
      return 3;
    } else if (ran >= 72998 && ran < 193848) {
      return 4;
    } else if (ran >= 193848 && ran < 387207) {
      return 5;
    } else if (ran >= 387207 && ran < 612793) {
      return 6;
    } else if (ran >= 612793 && ran < 806152) {
      return 7;
    } else if (ran >= 806152 && ran < 927002) {
      return 8;
    } else if (ran >= 927002 && ran < 980713) {
      return 9;
    } else if (ran >= 980713 && ran < 996826) {
      return 10;
    } else if (ran >= 996826 && ran < 999756) {
      return 11;
    } else if (ran >= 999756 && ran < 1000000) {
      return 12;
    }

    return 6;    
  }

  fun getIndexFromOddRow11(ran: Int): Int {

    if (ran >= 0 && ran < 488) {
      return 0;
    } else if (ran >= 488 && ran < 5859) {
      return 1;
    } else if (ran >= 5859 && ran < 32714) {
      return 2;
    } else if (ran >= 32714 && ran < 113280) {
      return 3;
    } else if (ran >= 113280 && ran < 274413) {
      return 4;
    } else if (ran >= 274413 && ran < 500000) {
      return 5;
    } else if (ran >= 500000 && ran < 725587) {
      return 6;
    } else if (ran >= 725587 && ran < 886720) {
      return 7;
    } else if (ran >= 886720 && ran < 967286) {
      return 8;
    } else if (ran >= 967286 && ran < 994141) {
      return 9;
    } else if (ran >= 994141 && ran < 999512) {
      return 10;
    } else if (ran >= 999512 && ran < 1000000) {
      return 11;
    }

    return 5;    
  }

  fun getIndexFromOddRow10(ran: Int): Int {

    if (ran >= 0 && ran < 976) {
      return 0;
    } else if (ran >= 976 && ran < 10742) {
      return 1;
    } else if (ran >= 10742 && ran < 54687) {
      return 2;
    } else if (ran >= 54687 && ran < 171875) {
      return 3;
    } else if (ran >= 171875 && ran < 376953) {
      return 4;
    } else if (ran >= 376953 && ran < 623047) {
      return 5;
    } else if (ran >= 623047 && ran < 828125) {
      return 6;
    } else if (ran >= 828125 && ran < 945313) {
      return 7;
    } else if (ran >= 945313 && ran < 989258) {
      return 8;
    } else if (ran >= 989258 && ran < 999024) {
      return 9;
    } else if (ran >= 999024 && ran < 1000000) {
      return 10;
    }

    return 5;    
  }

  fun getIndexFromOddRow9(ran: Int): Int {

    if (ran >= 0 && ran < 1952) {
      return 0;
    } else if (ran >= 1952 && ran < 19530) {
      return 1;
    } else if (ran >= 19530 && ran < 89843) {
      return 2;
    } else if (ran >= 89843 && ran < 253906) {
      return 3;
    } else if (ran >= 253906 && ran < 500000) {
      return 4;
    } else if (ran >= 500000 && ran < 746094) {
      return 5;
    } else if (ran >= 746094 && ran < 910157) {
      return 6;
    } else if (ran >= 910157 && ran < 980470) {
      return 7;
    } else if (ran >= 980470 && ran < 998048) {
      return 8;
    } else if (ran >= 998048 && ran < 1000000) {
      return 9;
    }

    return 4;    
  }

  fun getIndexFromOddRow8(ran: Int): Int {

    if (ran >= 0 && ran < 3906) {
      return 0;
    } else if (ran >= 3906 && ran < 35156) {
      return 1;
    } else if (ran >= 35156 && ran < 144531) {
      return 2;
    } else if (ran >= 144531 && ran < 363281) {
      return 3;
    } else if (ran >= 363281 && ran < 636719) {
      return 4;
    } else if (ran >= 636719 && ran < 855469) {
      return 5;
    } else if (ran >= 855469 && ran < 964844) {
      return 6;
    } else if (ran >= 964844 && ran < 996094) {
      return 7;
    } else if (ran >= 996094 && ran < 1000000) {
      return 8;
    }

    return 4;    
  }

  fun getIndexGeneral(rows: Int, ran: Int): Int {
    if (rows == 8) {
      return self.getIndexFromOddRow8(ran);
    } else if (rows == 9) {
      return self.getIndexFromOddRow9(ran);
    } else if (rows == 10) {
      return self.getIndexFromOddRow10(ran);
    } else if (rows == 11) {
      return self.getIndexFromOddRow11(ran);
    } else if (rows == 12) {
      return self.getIndexFromOddRow12(ran);
    } else if (rows == 13) {
      return self.getIndexFromOddRow13(ran);
    } else if (rows == 14) {
      return self.getIndexFromOddRow14(ran);
    } else if (rows == 15) {
      return self.getIndexFromOddRow15(ran);
    } else if (rows == 16) {
      return self.getIndexFromOddRow16(ran);
    }

    return self.getIndexFromOddRow16(ran);
  }

  receive(msg: GamePayoutSlim) {

    require(msg.value >= ton("0.01"), "not less than 0.01 TON to play");
    require(msg.value < ((myBalance() / 1000) - self.MinTonForStorage), "enough funds in balance for payout");

    let ctx: Context = context();
    require((msg.value + ton("0.01")) <= ctx.value, "message malformed, ton value not matching");
    
    dump(msg.value);

    nativeRandomizeLt();
    let oddStep: Int = random(0,1000000);
    let idxWon = self.getIndexGeneral(msg.rows, oddStep);
    let multiplier = self.slot_universe.slots.get(msg.rows)!!.slot_risk.get(msg.risks)!!.slot.get(idxWon)!!;
   
    let response = GamePayoutSlimResponse {
      winAmount: (msg.value * multiplier) / 10,
      winMultipler: multiplier,
      lastPathIdx: idxWon,
      rows: msg.rows,
      risks: msg.risks
    };

    dump(response.winAmount);
    dump(response.winMultipler);
    dump(response.lastPathIdx);

    send(SendParameters{
        to: sender(),
        bounce: true,
        value: response.winAmount,
        mode: SendIgnoreErrors | SendPayGasSeparately,
        body: response.toCell(),
    });

  }

  receive(msg: MultiGamePayoutSlim) {

    require(msg.valuePerIteration >= ton("0.01"), "not less than 0.01 TON to play");
    require(msg.iterations >= 2, "minimum 2 iterations");

    let ctx: Context = context();
    require(((msg.valuePerIteration * msg.iterations) + (msg.iterations * ton("0.008"))) <= ctx.value, "message malformed, ton value not matching");
    require((msg.valuePerIteration * msg.iterations) < ((myBalance() / 1000) - self.MinTonForStorage), "enough funds in balance for payout");

    let responsecall = MultiGamePayoutSlimResponse {
      winTotalAmount: 0,
      winAmount: emptyMap(),
      winMultipler: emptyMap(),
      lastPathIdx: emptyMap(),
      iterationCount: msg.iterations
    };

    nativeRandomizeLt();
    let countResponse: Int = 0;
    repeat (msg.iterations) {
      let oddStep: Int = random(0,1000000);
      let idxWon = self.getIndexGeneral(msg.rows, oddStep);
      let multiplier = self.slot_universe.slots.get(msg.rows)!!.slot_risk.get(msg.risks)!!.slot.get(idxWon)!!;
      let totalWin = (msg.valuePerIteration * multiplier) / 10;
      responsecall.winTotalAmount = responsecall.winTotalAmount + totalWin;
      responsecall.winAmount.set(countResponse, totalWin);
      responsecall.winMultipler.set(countResponse, multiplier);
      responsecall.lastPathIdx.set(countResponse, idxWon);

      countResponse = countResponse + 1;
    }

    dump(responsecall.winTotalAmount);
    dump(responsecall.winMultipler);
    dump(responsecall.lastPathIdx);

    send(SendParameters{
        to: sender(),
        bounce: true,
        value: responsecall.winTotalAmount,
        mode: SendIgnoreErrors | SendPayGasSeparately,
        body: responsecall.toCell(),
    });

  }

  receive(msg: FundPayout) {

    require(self.owner == sender(), "sender not permitted");
    let ctx: Context = context();
    require(msg.value == ctx.value, "message malformed, ton value not matching");
    
    dump(ctx.value);

  }

  receive(msg: Withdraw) {

    require(self.owner == sender(), "sender not permitted");
    let amount: Int = min(msg.amount, myBalance() - context().value - self.MinTonForStorage);
    require(amount > 0, "Insufficient balance");
    send(SendParameters{
        to: sender(),
        bounce: true,
        value: amount,
        mode: SendRemainingValue + SendIgnoreErrors
    });

  }

  get fun totalBalance(): Int {
    return myBalance();
  }

  get fun totalBalanceString(): String {
    return myBalance().toCoinsString();
  }
  
}