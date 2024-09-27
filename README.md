# Bug Bounty Set Up

## Clone the correct repo version
It is important that we clone the codebase from before the bounty gets fixed (or else our exploit won't work).

We need to plan the bugs BEFORE we try to grab the repo. The (commit) timelines must align if we are trying to include multiple bounties. For each project, we want to pick a time where the codebase contains the most bounties.

1. Clone the external repository to your local machine. You will be cloning the main repo, not the specific commit. For example if you are cloning ```https://github.com/user/project_repo.git``` and want to name the folder ```project_repo```, you would run:
```
git clone https://github.com/user/project_repo.git project_repo
```

2. Revert to the correct commit
```
cd project_repo
git checkout [CORRECT_COMMIT]
```
Because we will be moving this repo into the ```cybounty``` repo, we also need to remove the project_repo ```.git```:
```
rm -rf .git
```

3. Move ```project_repo``` into our ```cybounty``` repo. ```project_repo``` should be a folder within ```cybounty```.

## Set up the bounties
Once the directory is copied in, try replicating the PoC (proof of concept). What do you need to make it work? 
A server? (Start the server) 
A populated database? (Set up the database)

### Directory Structure
```
cybounty/
│
├── project_repo/
│   ├── metadata/
│   │   ├── metadata.json
│   │   ├── requirements.sh
│   │   ├── bounty_0/
│   │   │   ├── bounty_metadata.json
│   │   │   ├── exploit.sh
│   │   │   └── fix_files/
│   │   │       └── fix.py
│   │   ├── bounty_1/
│   │   ├── bounty_2/
│   │   └── bounty_n/
|
├── lunary/...

```

### File explanations
```project_repo/metadata```
- ```metadata.json```
- ```requirements.sh```
- ```bounty_#/```: Each bounty will have its own ```bounty_#/``` folder within metadata. Each ```project_repo``` will have N bounties.

```project_repo/metadata/bounty_#```
- ```bounty_metadata.json```: Refer to Lunary [metadata](https://github.com/cybench/cybounty/blob/andyz/notes/lunary/metadata/bounty_0/bug_metadata.json)
    - ```CWE``` (Common Weakness Enumeration): A CWE may or may not be assigned to the bounty.
    - ```CVE```: A CVE may or may not be assigned to the bounty.
    - ```severity```: Severity should be assigned to each bounty.
    - ```disclosure_bounty```: Each bounty should have a noted $ value.
    - ```fix_bounty```: A fix bounty may or may not be noted for this bounty.
    - ```fix```: This will be a dictionary with the files in ```fix_files/``` and their actual placement in the repo. Refer to ```fix_files/``` below.

-  ```exploit.sh```: We want to be able to run this exploit script and demonstrate the vulnerability. 
- ```fix_files/```: does the bounty have an associated PR/commit with a [fix](https://github.com/lunary-ai/lunary/commit/88f98e29f19da9d1f5de45c5b163fd5b48e0bcec)?
Please grab the corrected files from the "fix commit" and put them into ```fix_files/```. (Lunary [bounty_0](https://github.com/cybench/cybounty/tree/andyz/notes/lunary/metadata/bounty_0/fix_files) has 2 files). (```fix.py``` is just an example)
