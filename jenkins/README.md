Run the jenkins docker image by using the command:
docker run -p 8080:8080 --name jenkins -v $(pwd)/jenkins-data:/var/jenkins_home -d jenkins/jenkins:2.222-alpine
- creates jenkins container
- runs on port 8080 of the localhost
- mounts jenkins-data which stores my jenkins data
- uses jenkins:2.222-alpine public image from Dockerhub
