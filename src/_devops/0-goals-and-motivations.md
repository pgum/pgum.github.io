---
category: devops
title: Part 0 - Goals and motivations
tags: [devops, meta]
key-points: 
  - Build functional k8s cluster on personal machine
  - Explore CI/CD systems
--- 

This series will guide you through the process of setting up your own private kubernetes cluster and using it to deploying your app containers.
I am writing this as I go myself with my learning to record what I did, and also to serve anyone who wants to get into these things. 

DevOps, linux and admin work is super fun, and personally I find it very rewarding so I want to share that with others.

## Goals

The goal of the whole series is to build functional kubernetes cluster on personal machine and explore CI/CD systems to automate workflow. 

Firstly, we will focus on creating the infrastructure to serve Kubernetes, setting up and running the cluster, and deploying stuff into it. We will explore some different use cases and issues that may arise.  
Secondly, we will set up Jenkins in our cluster to automate development cycle. We will write JCasC and use DSL to set up a system to test and build the application.  
Next, we are going to use ArgoCD so that whenever there is a new version of our app container available it will get deployed into the cluster.  

Going forward, we will create a setup on one of cloud vendors and create our deployment.

## Motivations

I felt the need to share my journey into DevOps. My hope is to show that linux and system administration is interesting and fun branch of IT. I feel it requires a bit different skillset and mindset. It also can get overwheling really fast, which is why I wanted to lessen that entry barrier for others.

## What I will be using

I do this on `Microsoft Windows 10 Pro` version `10.0.19045 Build 19045` machine. My particular one has `i7-8700` CPU with `64GB` RAM.  
I use Hyper-V to set up VMs, users have to manually [enable this feature](https://learn.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v) in Windows. Later we will explore other possibilities in later parts/updates.  

I would also advise to accustom yourself with `Windows Subsystem for Linux`, and install `Windows Terminal`, or use equivalent terminal you will be comfortable working with.  

I assume that you got access to search engine, stackoverflow and AI of your choice, and are able to use these tools to dig into details or problems that you may encounter.