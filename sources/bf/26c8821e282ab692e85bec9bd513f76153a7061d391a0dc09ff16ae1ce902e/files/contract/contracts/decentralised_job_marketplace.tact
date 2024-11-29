import "@stdlib/deploy";
import "./message.tact";

contract DecentralisedJobMarketplace with Deployable {
    // Mapping of job IDs to job details
    jobs: map<Int, Job>;
    jobCounter: Int;

    // Mapping of post IDs to post details
    posts: map<Int, Post>;
    postCounter: Int;

    // Address of the NFT collection
    nftCollection: Address;

    users: map<Address, User>;

    init(nftCollection: Address){
        self.jobCounter = 0;
        self.postCounter = 0;
        self.nftCollection = nftCollection;
    }

    receive(msg: CreateUser){
        let user = self.users.get(msg.address);
        require(user == null, "User already exists");
        self.users.set(msg.address, User{
            address: msg.address,
            name: msg.name,
            email: msg.email,
            skills: msg.skills,
            isEmployer: msg.isEmployer,
            reputations: emptyMap(),
            numberOfReputations: 0,
        });
        self.reply("Gas refund".asComment());
    }

    receive(msg: UpdateUserName){
        let user = self.users.get(msg.address);
        require(user != null, "User does not exist");
        self.users.set(msg.address, User{
            address: msg.address,
            name: msg.name,
            email: user!!.email,
            skills: user!!.skills,
            isEmployer: user!!.isEmployer,
            reputations: user!!.reputations,
            numberOfReputations: user!!.numberOfReputations,
        });
        self.reply("Gas refund".asComment());
    }

    receive(msg: UpdateUserEmail){
        let user = self.users.get(msg.address);
        require(user != null, "User does not exist");
        self.users.set(msg.address, User{
            address: msg.address,
            name: user!!.name,
            email: msg.email,
            skills: user!!.skills,
            isEmployer: user!!.isEmployer,
            reputations: user!!.reputations,
            numberOfReputations: user!!.numberOfReputations,
        });
        self.reply("Gas refund".asComment());
    }

    receive(msg: UpdateUserRole){
        let user = self.users.get(msg.address);
        require(user != null, "User does not exist");
        self.users.set(msg.address, User{
            address: msg.address,
            name: user!!.name,
            email: user!!.email,
            skills: user!!.skills,
            isEmployer: msg.isEmployer,
            reputations: user!!.reputations,
            numberOfReputations: user!!.numberOfReputations,
        });
        self.reply("Gas refund".asComment());
    }

    receive(msg: UpdateUserSkills){
        let user = self.users.get(msg.address);
        require(user != null, "User does not exist");
        self.users.set(msg.address, User{
            address: msg.address,
            name: user!!.name,
            email: user!!.email,
            skills: msg.skills,
            isEmployer: user!!.isEmployer,
            reputations: user!!.reputations,
            numberOfReputations: user!!.numberOfReputations,
        });
        self.reply("Gas refund".asComment());
    }

    receive(msg: CreateJob){
        let employer = context().sender;
        let user = self.users.get(employer);
        require(user != null, "Employer does not exist");
        require(user!!.isEmployer, "Sender is not an employer");
        require(msg.title != "", "Title cannot be empty");
        require(msg.description != "", "Description cannot be empty");
        require(context().value == msg.compensation, "Incorrect value sent");
        
        let jobId = self.jobCounter;
        self.jobCounter = self.jobCounter + 1;
        self.jobs.set(jobId, 
            Job{
                id: jobId,
                title: msg.title,
                description: msg.description,
                compensation: msg.compensation,
                skills: msg.skills,
                numberOfSkills: msg.numberOfSkills,
                employer: employer, 
                isAcceptingApplicants: true, 
                applicants: emptyMap(), 
                numberOfApplicants: 0, 
                createdAt: now(), 
            }
        );
        self.reply("Gas refund".asComment());
    }

    receive(msg: ApplyForJob){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let job: Job? = self.jobs.get(msg.job_id);
        require(job != null, "Job does not exist");
        require(job!!.isAcceptingApplicants, "Job is not accepting applicants");
        require(job!!.worker == null, "Job already assigned");

        let applicant = context().sender;
        let updatedApplicants = job!!.applicants;
        updatedApplicants.set(job!!.numberOfApplicants, applicant);
        let updatedJob = Job{
            id: job!!.id,
            title: job!!.title,
            description: job!!.description,
            compensation: job!!.compensation,
            skills: job!!.skills,
            numberOfSkills: job!!.numberOfSkills,
            employer: job!!.employer,
            worker: job!!.worker,
            isAcceptingApplicants: job!!.isAcceptingApplicants,
            isCompleted: job!!.isCompleted,
            applicants: updatedApplicants,
            numberOfApplicants: job!!.numberOfApplicants + 1,
            createdAt: job!!.createdAt,
            completedAt: job!!.completedAt,
        };
        self.jobs.set(msg.job_id, updatedJob);
        self.reply("Gas refund".asComment());
    }

    receive(msg: AcceptApplicant){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let job = self.jobs.get(msg.job_id);
        require(job != null, "Job does not exist");
        require(job!!.employer == context().sender, "Only employer can accept applicant");
        let updatedJob = Job{
            id: job!!.id,
            title: job!!.title,
            description: job!!.description,
            compensation: job!!.compensation,
            skills: job!!.skills,
            numberOfSkills: job!!.numberOfSkills,
            employer: job!!.employer,
            worker: msg.applicant,
            isAcceptingApplicants: false,
            isCompleted: false,
            applicants: job!!.applicants,
            numberOfApplicants: job!!.numberOfApplicants,
            createdAt: job!!.createdAt,
            completedAt: job!!.completedAt,
        };
        self.jobs.set(msg.job_id, updatedJob);
        self.reply("Gas refund".asComment());
    }

    receive(msg: CompleteJob){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let job = self.jobs.get(msg.job_id);
        require(job != null, "Job does not exist");
        require(job!!.worker == context().sender, "Only worker can complete job");
        require(job!!.isCompleted == false, "Job is already completed");

        let updatedJob = Job{
            id: job!!.id,
            title: job!!.title,
            description: job!!.description,
            compensation: job!!.compensation,
            skills: job!!.skills,
            numberOfSkills: job!!.numberOfSkills,
            employer: job!!.employer,
            worker: job!!.worker,
            isAcceptingApplicants: job!!.isAcceptingApplicants,
            isCompleted: job!!.isCompleted,
            worker_rating: job!!.worker_rating,
            worker_review: job!!.worker_review,
            applicants: job!!.applicants,
            numberOfApplicants: job!!.numberOfApplicants,
            createdAt: job!!.createdAt,
            completedAt: now(),
        };
        self.jobs.set(msg.job_id, updatedJob);
        let employer = self.users.get(job!!.employer);
        let updatedReputations = employer!!.reputations;
        let reviewBuilder = beginString();
        reviewBuilder.append(msg.employer_review);
        updatedReputations.set(employer!!.numberOfReputations, Reputation{
            rating: msg.employer_rating,
            review: reviewBuilder.toCell(),
        });
        self.users.set(job!!.employer, User{
            address: employer!!.address,
            name: employer!!.name,
            email: employer!!.email,
            skills: employer!!.skills,
            isEmployer: employer!!.isEmployer,
            reputations: updatedReputations,
            numberOfReputations: employer!!.numberOfReputations + 1,
        });
        // self.reply("Gas refund".asComment());
    }

    receive(msg: MarkJobCompleted){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let job = self.jobs.get(msg.job_id);
        require(job != null, "Job does not exist");
        require(job!!.worker != null, "Job is not assigned");
        require(job!!.employer == context().sender, "Only employer can complete job");
        require(job!!.isAcceptingApplicants == false, "Job is still accepting applicants");
        require(job!!.isCompleted == false, "Job is already completed");
        require(job!!.completedAt != null, "Job is not completed by worker");
        require(msg.worker_rating >= 1 && msg.worker_rating <= 5, "Worker rating must be between 1 and 5");
        let updatedJob = Job{
            id: job!!.id,
            title: job!!.title,
            description: job!!.description,
            compensation: job!!.compensation,
            skills: job!!.skills,
            numberOfSkills: job!!.numberOfSkills,
            employer: job!!.employer,
            worker: job!!.worker,
            isAcceptingApplicants: job!!.isAcceptingApplicants,
            isCompleted: true,
            worker_rating: msg.worker_rating,
            worker_review: msg.worker_review,
            applicants: job!!.applicants,
            numberOfApplicants: job!!.numberOfApplicants,
            createdAt: job!!.createdAt,
            completedAt: now(),
        };
        self.jobs.set(msg.job_id, updatedJob);
        let worker = self.users.get(job!!.worker!!);
        let updatedReputations = worker!!.reputations;
        let reviewBuilder = beginString();
        reviewBuilder.append(msg.worker_review);
        updatedReputations.set(worker!!.numberOfReputations, Reputation{
            rating: msg.worker_rating,
            review: reviewBuilder.toCell(),
        });
        self.users.set(job!!.worker!!, User{
            address: worker!!.address,
            name: worker!!.name,
            email: worker!!.email,
            skills: worker!!.skills,
            isEmployer: worker!!.isEmployer,
            reputations: updatedReputations,
            numberOfReputations: worker!!.numberOfReputations + 1,
        });

        send(SendParameters{
            to: self.nftCollection,
            value: ton("0.05"),
            mode: 0,
            body: Mint{
                recipient: job!!.worker!!,
                individual_content: msg.nft_metadata,
            }.toCell(),
        });

        if(job!!.compensation != null && job!!.compensation!! > 0){
            send(SendParameters{
                to: job!!.worker!!,
                value: job!!.compensation!!,
                mode: 0,
            });
        }
        self.reply("Gas refund".asComment());
    }

    receive(msg: CreatePost){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let postId = self.postCounter;
        self.postCounter = self.postCounter + 1;
        self.posts.set(postId, Post{
            id: postId,
            title: msg.title,
            content: msg.content,
            comments: emptyMap(),
            numberOfComments: 0,
            upvotes: 0,
            downvotes: 0,
            author: context().sender,
            createdAt: now(),
        });
        self.reply("Gas refund".asComment());
    }

    receive(msg: CreateComment){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let post = self.posts.get(msg.post_id);
        require(post != null, "Post does not exist");
        let commentId = post!!.numberOfComments;
        let updatedComments = post!!.comments;
        updatedComments.set(commentId, Comment{
            id: commentId,
            author: context().sender,
            content: msg.content,
            upvotes: 0,
            downvotes: 0,
        });
        self.posts.set(msg.post_id, Post{
            id: post!!.id,
            title: post!!.title,
            content: post!!.content,
            author: post!!.author,
            comments: updatedComments,
            numberOfComments: post!!.numberOfComments + 1,
            upvotes: post!!.upvotes,
            downvotes: post!!.downvotes,
            createdAt: post!!.createdAt,
        });
        self.reply("Gas refund".asComment());
    }

    receive(msg: UpvotePost){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let post = self.posts.get(msg.post_id);
        require(post != null, "Post does not exist");
        let updatedPost = Post{
            id: post!!.id,
            title: post!!.title,
            content: post!!.content,
            author: post!!.author,
            comments: post!!.comments,
            numberOfComments: post!!.numberOfComments,
            upvotes: post!!.upvotes + 1,
            downvotes: post!!.downvotes,
            createdAt: post!!.createdAt,
        };
        self.posts.set(msg.post_id, updatedPost);
        self.reply("Gas refund".asComment());
    }

    receive(msg: DownvotePost){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let post = self.posts.get(msg.post_id);
        require(post != null, "Post does not exist");
        let updatedPost = Post{
            id: post!!.id,
            title: post!!.title,
            content: post!!.content,
            author: post!!.author,
            comments: post!!.comments,
            numberOfComments: post!!.numberOfComments,
            upvotes: post!!.upvotes,
            downvotes: post!!.downvotes + 1,
            createdAt: post!!.createdAt,
        };
        self.posts.set(msg.post_id, updatedPost);
        self.reply("Gas refund".asComment());
    }

    receive(msg: ArchivePost){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let post = self.posts.get(msg.post_id);
        require(post != null, "Post does not exist");
        require(post!!.author == context().sender, "Only author can archive post");
        let updatedPost = Post{
            id: post!!.id,
            title: post!!.title,
            content: post!!.content,
            author: post!!.author,
            comments: post!!.comments,
            numberOfComments: post!!.numberOfComments,
            upvotes: post!!.upvotes,
            downvotes: post!!.downvotes,
            createdAt: post!!.createdAt,
            archivedAt: now(),
        };
        self.posts.set(msg.post_id, updatedPost);
        self.reply("Gas refund".asComment());
    }

    receive(msg: UpvoteComment){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let post = self.posts.get(msg.post_id);
        require(post != null, "Post does not exist");
        let comment = post!!.comments.get(msg.comment_id);
        require(comment != null, "Comment does not exist");
        let updatedComment = Comment{
            id: comment!!.id,
            author: comment!!.author,
            content: comment!!.content,
            upvotes: comment!!.upvotes + 1,
            downvotes: comment!!.downvotes,
        };
        let updatedComments = post!!.comments;
        updatedComments.set(msg.comment_id, updatedComment);
        self.posts.set(msg.post_id, Post{
            id: post!!.id,
            title: post!!.title,
            content: post!!.content,
            author: post!!.author,
            comments: updatedComments,
            numberOfComments: post!!.numberOfComments,
            upvotes: post!!.upvotes,
            downvotes: post!!.downvotes,
            createdAt: post!!.createdAt,
        });
        self.reply("Gas refund".asComment());
    }

    receive(msg: DownvoteComment){
        let user = self.users.get(context().sender);
        require(user != null, "User does not exist");
        let post = self.posts.get(msg.post_id);
        require(post != null, "Post does not exist");
        let comment = post!!.comments.get(msg.comment_id);
        require(comment != null, "Comment does not exist");
        let updatedComment = Comment{
            id: comment!!.id,
            author: comment!!.author,
            content: comment!!.content,
            upvotes: comment!!.upvotes,
            downvotes: comment!!.downvotes + 1,
        };
        let updatedComments = post!!.comments;
        updatedComments.set(msg.comment_id, updatedComment);
        self.posts.set(msg.post_id, Post{
            id: post!!.id,
            title: post!!.title,
            content: post!!.content,
            author: post!!.author,
            comments: updatedComments,
            numberOfComments: post!!.numberOfComments,
            upvotes: post!!.upvotes,
            downvotes: post!!.downvotes,
            createdAt: post!!.createdAt,
        });
        self.reply("Gas refund".asComment());
    }

    get fun nftCollection(): Address {
        return self.nftCollection;
    }

    get fun jobs(): map<Int, Job> {
        return self.jobs;
    }

    get fun job_count(): Int {
        return self.jobCounter;
    }

    get fun job(job_id: Int): Job? {
        return self.jobs.get(job_id);
    }

    get fun user(userAddress: Address): User {
        let _user = self.users.get(userAddress);
        if(_user == null){
            _user = User{
                address: userAddress,
                name: "",
                email: "",
                skills: emptyMap(),
                isEmployer: false,
                reputations: emptyMap(),
                numberOfReputations: 0,
            };
        }
        return _user!!;
    }

    get fun posts(): map<Int, Post> {
        return self.posts;
    }

    get fun post_count(): Int {
        return self.postCounter;
    }

    get fun post(post_id: Int): Post? {
        return self.posts.get(post_id);
    }
}
