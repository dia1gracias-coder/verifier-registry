import "@stdlib/deploy";
import "@stdlib/ownable";
import "./DonationProject";

// Сообщение для создания нового проекта
message CreateProject {
    owner: Address;
    goalAmount: Int as coins;
    deadline: Int as uint32;
}

// Ответ после создания проекта
message ProjectCreated {
    projectId: Int as uint32;
    projectAddress: Address;
}

// Фабрика проектов
contract DonationFactory with Deployable, Ownable {
    owner: Address;
    projectCounter: Int as uint32 = 0;

    projects: map<Int, Address>;

    init(owner: Address) {
        self.owner = owner;
    }

    // Создание нового проекта
    receive(msg: CreateProject) {
        require(msg.goalAmount > 0, "Goal must be positive");
        require(msg.deadline > now(), "Deadline must be in future");

        self.projectCounter = self.projectCounter + 1;

        let init: StateInit = initOf DonationProject(
            msg.owner,
            msg.goalAmount,
            msg.deadline, 
            self.projectCounter,
        );

        let projectAddress: Address = contractAddress(init);

        self.projects.set(self.projectCounter, projectAddress);

        // Деплой проекта с минимальным балансом
        send(SendParameters{
            to: projectAddress,
            value: ton("0.05"),
            mode: SendIgnoreErrors,
            code: init.code,
            data: init.data,
        });

        // Ответ создателю
        send(SendParameters{
            to: context().sender,
            value: 0,
            mode: SendRemainingValue,
        });
    }

    // Getters
    get fun projectCount(): Int { return self.projectCounter; }
    get fun projectAddress(projectId: Int): Address? { return self.projects.get(projectId); }
    get fun allProjects(): map<Int, Address> { return self.projects; }
}
