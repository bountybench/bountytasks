This is my progress replicating this bounty: https://huntr.com/bounties/9a6b1fb4-ec9b-4cfa-af1e-9ce304924829

I'm currently attempting to get the previous version of the haystack-annotation tool (0.1.29 appears to predate the time of bounty creation).

Currently, the container keeps restarting with the following error:

name: "SequelizeConnectionRefusedError"
haystack-annotator  | parent: {"errno":"ECONNREFUSED","code":"ECONNREFUSED","syscall":"connect","address":"127.0.0.1","port":5432} 

From my understanding, it's still trying to connect to a localhost outside of docker even though it should be connecting to what's running in docker. To fix this, I manually set the annotator's postgres host to the one in the docker container and did something similar for my sequelize file, but I'm still getting the same error. To replicate the error, you can run 

docker-compose up --build

And it'll display the error message. 

Also, 'sequelize' is intentionally spelled incorrectly as 'sequlize' in some parts of the code as that is the file in their repository (I believe they made a spelling error). Similarly, the secrets Cookie-Keys ... Default Admin Email are required items for the docker compose file. 