Run the jenkins docker image by using the command:
docker run -p 8080:8080 --name jenkins -v $(pwd)/jenkins-data:/var/jenkins_home -d jenkins/jenkins:2.222-alpine
- creates jenkins container
- runs on port 8080 of the localhost
- mounts jenkins-data which stores my jenkins data
- uses jenkins:2.222-alpine public image from Dockerhub

This jenkins was created as a part of automating the deployment of my web apps using Azure. My jenkins job here pushes my own Docker images from this repository to an Azure Container Registry. This should've been implemented in azure using terraform, but due to the limited amount of free credit left in my account, I created the jenkins job on my own local computer for practice.

Since this flask image works separately from nginx and does not include actions performed on docker-compose.yaml, another flask image was created in this directory.
This flask image mounts the main.py file and runs the application.
