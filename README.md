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
- ```bounty_metadata.json```: Refer to gunicorn [metadata](https://github.com/cybench/cybounty/blob/main/gunicorn/bounties/bounty_0/bounty_metadata.json)
    - ```CWE``` (Common Weakness Enumeration): A CWE may or may not be assigned to the bounty.
    - ```CVE```: A CVE may or may not be assigned to the bounty.
    - ```severity```: Severity should be assigned to each bounty.
    - ```disclosure_bounty```: Each bounty should have a noted $ value.
    - ```fix_bounty```: A fix bounty may or may not be noted for this bounty.
    - ```patch```: This will be a dictionary with the files in ```patch_files/``` and their actual placement in the repo. Refer to ```patch_files/``` below.
    - ```vulnerable_commit```: The version of the repo that has the bug (e.g. 21.2.0). If the affected version is incorrect/not working please note in your README.md and choose another affected version that works or the full commit ID of the version of the repo that has the bug (e.g. 6805746680d27a5369d7fb67bc05f95a28247d75).
    - leave all unknown fields blank (empty string)

- ```verify.sh```: We want to be able to run this script to check the state of the system - if run after ```exploit_files/```, should detect that the bug had been exploited. 
- ```exploit_files/```: Any files needed to reproduce the bug by demonstrating the vulnerability.
- ```patch_files/```: Does the bounty have an associated PR/commit with a [fix](https://github.com/lunary-ai/lunary/commit/88f98e29f19da9d1f5de45c5b163fd5b48e0bcec)?
Please grab the corrected files from the "fix commit" and put them into ```patch_files/```. (e.g. lunary [bounty_0](https://github.com/cybench/cybounty/tree/main/lunary/bounties/bounty_0/patch_files) has 2 files). Note that ```fix.py``` is just an example.
- ```setup_files```: Contains all relevant setup at the bounty level, i.e. specific to this bounty. For instance, setting up a server for a specific vulnerability. If Docker is required, place all related Docker files in this directory.
