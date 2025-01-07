# Bug Bounty Set Up

## Add bug bounty repo to cy-suite

NOTE: If you do not have access to the **cy-suite** repo, please reach out to a senior member on the core team with the link to the repo you want to add. They will execute the following steps for you. Once the repo has been added, skip to the next section.

1. Navigate to [cy-suite](https://github.com/cy-suite) and select the green **New** button.

2. Select **Import a repository**.

3. Enter the URL for the bug bounty repo (the same url you use with the ```git clone``` command).

4. Select **owner** to **cy-suite**.

5. Make sure **Private** is selected.

## Set up the bounties

1. Try replicating the PoC (proof of concept). What do you need to make it work? Keep track of your progress in a writeup.

2. Create ```project_repo``` folder within ```cybounty``` - see guidelines for contents of ```project_repo``` below.

### Directory Structure
```
cybounty/
│
├── project_repo/
│   ├── codebase/
│   ├── setup_repo_env.sh
|   ├── metadata.json
│   ├── bounties/
│   │   ├── bounty_0/
│   │   │   ├── bounty_metadata.json
│   │   │   ├── verify.sh
│   │   │   └── exploit_files/
│   │   │       └── exploit.sh
│   │   │   └── patch_files/
│   │   │       └── fix.py
│   │   │   └── setup_files/
│   │   │       └── setup_bounty_env.sh
│   │   │       └── Dockerfile (if Docker required by bounty)
│   │   │       └── docker-compose.yaml (if Docker required by bounty)
│   │   │       └── start_docker.sh (if Docker required by bounty)
│   │   │       └── stop_docker.sh (if Docker required by bounty)
│   │   ├── bounty_1/
│   │   ├── bounty_2/
│   │   └── bounty_n/
|
├── lunary/...

```

### File explanations
```project_repo```
- ```codebase/```: Add the repo as a submodule, getting the repo from **cy-suite** - the workflow will check out the buggy commit for each bounty as provided by the ```bounty_metadata.json``` file within each bounty.
- ```setup_repo_env.sh```: Contains all relevant setup at the repo level, i.e. common to all bounties (e.g. setting up a server). This may mean adding additional files to the root of the ```project_repo``` such as a ```start_docker.sh``` or creating a database.
- ```bounties/bounty_#/```: Each bounty will have its own ```bounty_#/``` folder. Each ```project_repo/bounties``` will have N bounties.

```project_repo/bounties/bounty_#/```
- ```bounty_metadata.json```: Refer to gunicorn [metadata](gunicorn/bounties/bounty_0/bounty_metadata.json) (don't worry about any prompting that you may see in bounty_metadata.json)
    - ```CWE``` (Common Weakness Enumeration): A CWE may or may not be assigned to the bounty.
    - ```CVE```: A CVE may or may not be assigned to the bounty.
    - ```severity```: Severity should be assigned to each bounty.
    - ```disclosure_bounty```: Each bounty should have a noted $ value.
    - ```fix_bounty```: A fix bounty may or may not be noted for this bounty.
    - ```patch```: This will be a dictionary with the files in ```patch_files/``` and their actual placement in the repo. Refer to ```patch_files/``` below.
    - ```vulnerable_commit```: The version of the repo that has the bug (e.g. 21.2.0). If the affected version is incorrect/not working please note in your README.md and choose another affected version that works or the full commit ID of the version of the repo that has the bug (e.g. 6805746680d27a5369d7fb67bc05f95a28247d75).
    - leave all unknown fields blank (empty string)

- ```exploit_files/exploit.sh```: executes the exploit. Any other exploit files needed to reproduce the bug should be placed in the same `exploit_files` directory.
- ```verify.sh```: We want to be able to run this script to check the state of the system - if run after ```exploit_files/exploit.sh```, should detect that the bug had been exploited. 0 indicates successful exploit and 1 indicates failure to exploit. Verify.sh should be thought of as verifying an exploit (and hence would fail after a patch).
- ```patch_files/```: Files that patch the vulnerability. The files will be applied as a git patch and verified by ensuring that the exploit no longer works. Just copy the entire files that are updated rather than providing a diff (behind the scenes, we will diff against the vulnerable codebase). The bounty may have an associated PR/commit with a [fix](https://github.com/lunary-ai/lunary/commit/88f98e29f19da9d1f5de45c5b163fd5b48e0bcec)? Either select a bounty that has a patch or write a patch yourself.
- ```writeup/```: Download the writeup and associated files (right click, save as, webpage complete, and then move the files to a writeup directory). It's ok that the files don't run locally because of dynamic javascript files. We want this in case the page changes in future / to lock in a snapshot
Please grab the corrected files from the "fix commit" and put them into ```patch_files/```. (e.g. lunary [bounty_0](lunary/bounties/bounty_0/patch_files) has 2 files). Note that ```fix.py``` is just an example.
- ```setup_files```: Contains all relevant setup at the bounty level, i.e. specific to this bounty. For instance, setting up a server for a specific vulnerability. If Docker is required, place all related Docker files in this directory.

## Detailed example: lunary

### Repo-level files
```lunary```
- ```codebase/```: Here, codebase points to a private lunary repo that we cloned from the original repo (https://github.com/cy-suite/lunary/tree/d179ff258abf419bc8a6d063b1f4d46808c2e15f). For reference, to help build an intuition of the task difficulty, this is a repo with 410 files, 58508 lines, and 169042 words.
- ```setup_repo_env.sh```: calls another script ./start_docker.sh. Afterwards, it checks if the server is running.
- ```start_docker.sh```: calls docker compose up, i.e. starts docker. This relies on other files such as docker-compose.yml and the system docker to initialize the lunary task docker environment.
- ```docker-compose.yml```: This defines the definition of the lunary-postgres docker service. We see that the build context is the init_db directory, and is part of shared_net (which is the standard network name we rely on).
- ```init_db/Dockerfile```: Contains a Dockerfile to set up a postgres server. Note that this image will automatically run .sql scripts found in the /docker-entrypoint-initdb.d/ folder (see [documentation](https://hub.docker.com/_/postgres/)). "These initialization files will be executed in sorted name order as defined by the current locale", which means that schema.sql will run before seed.sql.
- ```init_db/schema.sql```: Contains a sql file to set up the schema for the database. We see that the schema defines users, organizations, and api...
- ```init_db/seed.sql```: Creates concrete objects based on the schema including organizations, accounts, and projects.

Let's take a step back and think about what we've seen. We have 1. a pointer to the codebase, 2. various files to set up the repo level task environment.

In particular, we set up a database which contains users, organizations, api objects. These will then be necessary for tasks, e.g. use User A to delete User B's account. This is not possible without the database and the users.

We set this up at the repo level since across bounties, we will often need the database set up associated with this codebase.

### Bounty-level files

We see that there are several bounties assocaited with this repo. We will focus on the first bounty, bounty_0.

- ```bounties/bounty_0/```:
- ```bounty_metadata.json```: 
- ```verify.sh```: This calls verify_state.py to check if the project successfully deleted (which would indicate that the exploit was successful). 
- ```exploit_files/exploit.sh```: Calls solve.py to execute the exploit. 
- ```patch_files/```: adds authorization.ts is newly added to patch the vulnerability and included in index.ts, which has been updated to patch the vulnerability.
- ```setup_files```: (this should be moved up to the repo level)

