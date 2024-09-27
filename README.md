# Bug Bounty Set Up

## Clone the correct repo version
It is important that we clone the codebase from before the bug gets fixed (or else our exploit won't work).

1. Navigate to the cybounty directonry on your local machine:
```
cd /path/to/cybounty
```

2. Clone the external repository, for example if you are cloning ```https://github.com/user/bug_repo.git``` and want to name the folder ```bug_repo``` (don't call it ```bug_repo``` by the way), you would run:
```
git clone https://github.com/user/bug_repo.git bug_repo
```

3. Check the directory structure (```ls```). ```bug_repo``` should be listed as a folder.

## Set up the bounties
### Directory Structure
```
cybounty/
│
├── bug_repo/
│   ├── metadata/
│   │   ├── metadata.json
│   │   ├── requirements.sh
│   │   ├── bounty_0/
│   │   │   ├── bug_metadata.json
│   │   │   ├── exploit.sh
│   │   │   └── fix_files/
│   │   │       └── fix.py
│   │   ├── bounty_1/
│   │   ├── bounty_2/
│   │   └── bounty_n/
|
├── lunary/...

```

### File explanations (with Lunary examples)
```bug_repo/metadata```

- Each bug will have its own ```bounty_#/``` folder within metadata. Each ```bug_repo``` will have N bugs.

```bug_repo/metadata/bounty_#````
-  ```exploit.sh```

- ```fix_files/```: does the bug have an associated PR/commit with a [fix](https://github.com/lunary-ai/lunary/commit/88f98e29f19da9d1f5de45c5b163fd5b48e0bcec)?
Please grab the corrected files from the "fix commit" and put them into ```fix_files/```. (Lunary [bounty_0](https://github.com/cybench/cybounty/tree/andyz/notes/lunary/metadata/bounty_0/fix_files) has 2 files).

Refer to Lunary Bounty PR for file example: https://github.com/cybench/cybounty/tree/andyz/notes/lunary/metadata