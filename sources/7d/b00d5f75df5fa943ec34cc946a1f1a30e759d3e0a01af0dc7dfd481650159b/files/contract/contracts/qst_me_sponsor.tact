import "@stdlib/deploy";

import "./structs/assets.tact";
import "./messages.tact";

contract QstMeSponsor with Deployable {
  sponsorId: Int;
  parent: Address;
  sponsored: Int as coins;
  sponsoredAssets: Assets;
  communityPercent: Int as uint16;
  activeUntil: Int as uint64;
  threshold: Int as coins;

  init(
    parent: Address,
    sponsorId: Int
  ) {
    self.parent = parent;
    self.sponsorId = sponsorId;
    self.sponsoredAssets = Assets { ton: 0, usdt: 0 };
    self.communityPercent = 2000;
    self.activeUntil = 0;
    self.threshold = 0;
    self.sponsored = 0;
  }

  receive(msg: InternalResetSponsor) {
    require(self.sponsorId == msg.sponsorId, "Invalid sponsorId");
    require(sender() == self.parent, "Only main contract can reset sponsor");

    self.sponsored = 0;
    self.sponsoredAssets = Assets { ton: 0, usdt: 0 };
    self.communityPercent = msg.communityPercent;
    self.threshold = msg.threshold;

    self.forward(
      msg.initiator,
      SponsorReset{
        sponsorId: self.sponsorId,
        communityPercent: self.communityPercent,
        threshold: self.threshold,
      }.toCell(),
      false,
      null
    );
  }

  receive(msg: InternalSetCommunityPercent) {
    require(sender() == self.parent, "Only main contract can set community percent");
    self.communityPercent = msg.percent;

    self.forward(
      msg.initiator,
      CommunityPercentSet{
        sponsorId: self.sponsorId,
        percent: msg.percent,
      }.toCell(),
      false,
      null
    );
  }

  receive(msg: InternalRegisterSponsorship) {
    require(sender() == self.parent, "Only main contract can register sponsorship");

    self.sponsoredAssets = self.sponsoredAssets.add(msg.amount);
    self.sponsored += self.calculateSponsoredAmount(self.sponsoredAssets);

    if (self.sponsored >= self.threshold && !self.isActive()) {
      self.activeUntil = now() + 3600 * 24 * 30;
    }

    send(SendParameters{
      to: self.parent,
      value: 0,
      mode: SendRemainingValue | SendIgnoreErrors,
      body: InternalApproveSponsorship {
          sponsorId: self.sponsorId,
          amount: msg.amount,
          communityPercent: self.communityPercent,
          initiator: msg.initiator,
        }.toCell(),
    });
  }

  fun calculateSponsoredAmount(assets: Assets): Int {
    let sum = 0;

    if (assets.ton > 0) {
      sum += assets.ton;//TODO: implement price conversion
    }

    if (assets.usdt > 0) {
      sum += assets.usdt;
    }

    return sum;
  }

  get fun isActive(): Bool {
    return self.activeUntil > now();
  }

  get fun activeUntil(): Int {
    return self.activeUntil;
  }

  get fun threshold(): Int {
    return self.threshold;
  }

  get fun sponsored(): Int {
    return self.sponsored;
  }

  get fun sponsoredAssets(): Assets {
    return self.sponsoredAssets;
  }

  get fun communityPercent(): Int {
    return self.communityPercent;
  }
}
