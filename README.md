# dag - domain at glance 


> dag is a commandline bash tool that searches for a domain's DNS, WHOIS, and HTTP status. 

## Table of Contents

- [Description](#description)
- [Install](#install) 

## Description

[namho-kim](https://github.com/namho-kim) wrote this script to use at work - where we are constantly checking domain information. This tool grabs a lot of the important information at once, cutting down some time in our workflow. 

Because I use OSX at work, this tool was tested mostly for OSX use. I have found that certain Linux distros may not be able to properly run this app. Also, WHOIS outputs from the bash whois/jwhois is a bit inconsistent. 

## Install

Clone the repo, build an image from the enclosed Dockerfile, then use that to run the script in an ephemeral container:
> docker image build -t dag .

> docker container run --rm dag {domain}

Or, pull the image from Docker Hub: 
> docker pull mgibson323/dag; docker container run --rm mgibson323/dag {domain}
## License

This has no license - use it however you want.  
