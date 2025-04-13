// Смарт-контракт для управления участниками и голосованием в АНО "КТО с СВО"

import "@stdlib/deploy";
import "@stdlib/ownable";
// Структура для хранения информации о предложении
struct Proposal {
  // за
  votesFor: Int;
  // против
  votesAgainst: Int;
}
// Структура для хранения информации об агенте
struct Agent {
  // сила голоса
  votingPower: Int;
  // в составе учредителей или нет
  isFounder: Bool;
}

contract AnoKto with Deployable, Ownable {
  count: Int = 0;
  last_message: String? = null;
  last_sender: Address? = null;
  last_receiver: Address? = null;
  owner: Address;
  // Маппинг для хранения участников (адрес -> баланс голосов)
  members: map<Address, Int>;
  // Маппинг для хранения AI-агентов (адрес -> (баланс голосов, является ли учредителем))
  aiAgents: map<Address, Agent>;
  // Маппинг для хранения предложений (ID -> Proposal)
  proposals: map<Int, Proposal>;
  // Адрес председателя (chairman)
  chairman: Address;
  // Конструктор контракта
  init(chairman: Address){
    self.owner = chairman;
    self.chairman = chairman;
  }

  // Функция для добавления участника
  fun addMember(memberAddr: Address, votingPower: Int) {
    // Только председатель может добавлять участников
    require(sender() == self.chairman, "Only chairman can add members");
    self.members.set(memberAddr, votingPower);
  }

  fun delMember(memberAddr: Address) {
    self.members.del(memberAddr);
  }

  // Функция для добавления AI-агента

  fun addAIAgent(agentAddr: Address, votingPower: Int, isFounder: Bool) {
    // Только председатель может добавлять AI-агентов
    require(sender() == self.chairman, "Only chairman can add AI agents");
    let agent = Agent{votingPower: votingPower, isFounder: isFounder};
    self.aiAgents.set(agentAddr, agent);
  }

  fun delAIAgent(agentAddr: Address) {
    self.aiAgents.del(agentAddr);
  }

  // Функция для создания предложения

  fun createProposal(proposalId: Int) {
    // Только председатель или участник могут создавать предложения
    require(sender() == self.chairman ||
        self.members.exists(sender()) ||
        self.aiAgents.exists(sender()),
      "Only chairman, members or AI agents can create proposals"
    );
    self.proposals.set(proposalId, Proposal{votesFor: 0, votesAgainst: 0});
  }

  fun delProposal(proposalId: Int) {
    self.proposals.del(proposalId);
  }

  // Функция для голосования

  fun vote(proposalId: Int, voteFor: Bool) {
    // Предложение должно существовать
    require(self.proposals.exists(proposalId), "Proposal does not exist");
    // Голосовать могут только участники или AI-агенты
    require(self.members.exists(sender()) || self.aiAgents.exists(sender()),
      "Only members or AI agents can vote"
    );
    let votingPower: Int = 0;
    if (self.members.exists(sender())) {
      votingPower = self.members.get(sender())!!;
    } else {
      let agent: Agent = self.aiAgents.get(sender())!!;
      votingPower = agent.votingPower;
    }
    let proposal: Proposal = self.proposals.get(proposalId)!!;
    if (voteFor) {
      proposal.votesFor += votingPower;
    } else {
      proposal.votesAgainst += votingPower;
    }
    self.proposals.set(proposalId, proposal);
  }

  // Функция для получения результата голосования

  get fun getProposalResult(proposalId: Int): Proposal {
    // Предложение должно существовать
    require(self.proposals.exists(proposalId), "Proposal does not exist");
    let proposal: Proposal = self.proposals.get(proposalId)!!;
    return proposal;
  }

  // Функция для проверки, является ли AI-агент учредителем

  get fun isAIAgentFounder(agentAddr: Address): Bool {
    if (!self.aiAgents.exists(agentAddr)) {
      return false;
    }
    let agent: Agent = self.aiAgents.get(agentAddr)!!;
    return agent.isFounder;
  }

  // Точка входа контракта
  //  receive(msg: Slice){

  receive(str: String){
    send(SendParameters{
        to: self.owner,
        value: 0,
        mode: SendRemainingValue,
        body: str.asComment()
      }
    );
    // let ctx: Context
    self.storeStats(sender(), self.owner, str);
  }

  fun storeStats(sender: Address, receiver: Address, msg: String) {
    self.count += 1;
    self.last_message = msg;
    self.last_sender = sender;
    self.last_receiver = receiver;
  }

  fun _storeStats(msg: Slice) {
    // Разбираем сообщение
    let op: Int = msg.loadInt(32);
    if (op == 1) {
      // Добавить участника
      let memberAddr: Address = msg.loadAddress();
      let votingPower: Int = msg.loadInt(32);
      self.addMember(memberAddr, votingPower);
    }
    if (op == 2) {
      // Добавить AI-агента
      let agentAddr: Address = msg.loadAddress();
      let votingPower: Int = msg.loadInt(32);
      let isFounder: Bool = msg.loadInt(1) != 0;
      self.addAIAgent(agentAddr, votingPower, isFounder);
    }
    if (op == 3) {
      // Создать предложение
      let proposalId: Int = msg.loadInt(32);
      self.createProposal(proposalId);
    }
    if (op == 4) {
      // Проголосовать
      let proposalId: Int = msg.loadInt(32);
      let voteFor: Bool = msg.loadInt(1) != 0;
      self.vote(proposalId, voteFor);
    }
  }
}