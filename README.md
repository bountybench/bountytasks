# Bug Bounty Set Up

## Add bug bounty repo to TBD

1. Select the green ```New``` button

2. Select ```Import a repository```

3. Enter the URL for the bug bounty repo

4. Select ```owner`` to TBD

5. Make sure ```Private``` is selected.

2. Create ```project_repo``` folder within ```cybounty```.

## Set up the bounties
Try replicating the PoC (proof of concept). What do you need to make it work? Keep track of your progress in a writeup.

### Directory Structure
```
cybounty/
│
├── project_repo/
│   ├── bounties/
│   │   ├── codebase/
│   │   ├── setup_repo_env.sh
│   │   ├── bounty_0/
│   │   │   ├── bounty_metadata.json
│   │   │   ├── verify.sh
│   │   │   └── exploit_files/
│   │   │       └── exploit.sh
│   │   │   └── patch_files/
│   │   │       └── fix.py
│   │   ├── bounty_1/
│   │   ├── bounty_2/
│   │   └── bounty_n/
|
├── lunary/...

```

### File explanations
```project_repo/bounties```
- ```codebase/```: Add the repo as a submodule, getting the repo from TBD - the workflow will check out the buggy commit for each bounty as provided by the ```bounty_metadata.json``` file within each bounty
- ```setup_repo_env.sh```: contain all relevant setup at the repo level, i.e. common to all bounties (e.g. setting up a server)
- ```bounty_#/```: Each bounty will have its own ```bounty_#/``` folder. Each ```project_repo/bounties``` will have N bounties.

```project_repo/metadata/bounty_#```
- ```bounty_metadata.json```: Refer to gunicorn [metadata](https://github.com/cybench/cybounty/blob/main/gunicorn/bounties/bounty_0/bounty_metadata.json)
    - ```CWE``` (Common Weakness Enumeration): A CWE may or may not be assigned to the bounty.
    - ```CVE```: A CVE may or may not be assigned to the bounty.
    - ```severity```: Severity should be assigned to each bounty.
    - ```disclosure_bounty```: Each bounty should have a noted $ value.
    - ```fix_bounty```: A fix bounty may or may not be noted for this bounty.
    - ```patch```: This will be a dictionary with the files in ```patch_files/``` and their actual placement in the repo. Refer to ```patch_files/``` below.
    - leave all unknown fields blank (empty string)

- ```verify.sh```: We want to be able to run this script to check the state of the system - if run after ```exploit_files/```, should detect that the bug had been exploited. 
- ```exploit_files/```: Any files needed to reproduce the bug by demonstrating the vulnerability
- ```patch_files/```: Does the bounty have an associated PR/commit with a [fix](https://github.com/lunary-ai/lunary/commit/88f98e29f19da9d1f5de45c5b163fd5b48e0bcec)?
Please grab the corrected files from the "fix commit" and put them into ```patch_files/```. (e.g. lunary [bounty_0](https://github.com/cybench/cybounty/tree/andyz/notes/lunary/metadata/bounty_0/fix_files) has 2 files). (```fix.py``` is just an example)