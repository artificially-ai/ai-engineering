# Artificial Intelligence Engineering

This repository contains a Proof of Concept on how to integrate Jupyter Notebooks
with MLflow, for AI models versioning and serving, and SFTP & Minio for artefacts
storage.

The PoC has been implemented in a way to mimic MLflow running as a remote tracking
server, as a Docker container, and the SFTP and Minio also running as docker
containers. To ease the way the Jupyter notebooks communicate with
the MLflow tracking server, Jupyter Lab has also runs within a Docker container.

All the three containers run with the assistance of Docker Compose, which also
configures a custom network which is shared amongst the containers.

## Dependencies

To get this PoC running on a MacBook Pro, one needs to install the following applications:

* [Docker Engine](https://hub.docker.com/editions/community/docker-ce-desktop-mac)

If you are not a fan of Docker and would like to have only JupyterLab and MLflow
running locally, you will need the following:

* [Anaconda](https://docs.anaconda.com/anaconda/install/mac-os/)

After Anaconda is installed, you can create an environment based on the `environment.yml`
file that is part of this repository. You can find more information about managing
Anaconda environments [here](https://conda.io/projects/continuumio-conda/en/latest/user-guide/getting-started.html#managing-environments).

**Remark**: this repository will focus on running the dockerised version of the
proposed solution. If you are not a Docker fan, I suggest you start being otherwise
life will become difficult for you.

## Containers

The three containers used are named as:

1. `ekholabs-minio`:
   - based on the `minio/minio` image.
2. `ekholabs-sftp`:
   - based on the `atmoz/sftp` image.
3. `ekholabs-mlflow`:
   - built from the `Dockerfile.mlflowserver`.
4. `ekholabs-jupyterlab`:
   - built from the `Dockerfile.jupyterlab`.

## Architecture

A picture is worth a thousand words. When the picture is in `ASCII`, it's
even better! ;)

```ascii
 -- MacBook Dev Environment ----------------------------------
|                                                             |
|                -- Docker Engine ------------------------    |
|               |                                         |   |
|    ------     |      ------------            --------   |   |
|   | User | -------> | JupyterLab | -------> | MLflow |  |   |
|    ------     |      ------------            --------   |   |
|      ^        |            |                  /  |      |   |
|      |        |            |                 /   |      |   |
|       --------|------------|----------------     |      |   |
|               |            |                     |      |   |
|               |            | ---------           |      |   |
|               |            |          |          |      |   |
|               |            V          V          |      |   |
|               |         ------     -------       |      |   |
|               |        | SFTP |   | Minio | <----       |   |
|               |         ------     -------       |      |   |
|               |            ^                     |      |   |
|               |            |                     |      |   |
|               |             ---------------------       |   |
|                -----------------------------------------    |
|                                                             |
 -------------------------------------------------------------
```

1. User runs models on notebooks served by JupyterLab;
2. JupyterLab notebooks store metrics, parameters and model on MLflow
   file storage;
3. JupyterLab notebooks store artefacts (aka model files) in the SFTP or Minio
   server, it depends on which experiment id is being used. The files are
   identified by the run id from MLflow;
4. The user can browse the experiments on MLflow via its UI.
5. The bickets kept on Minio are accessible via its UI.

For the purpose of this PoC, the containers run on a local machine, MacBook Pro.
However, for a robust and resilient experience, it is recommended that both MLflow
and SFTP servers run on different machines. In addition to that, it is expected
that the volumes used for storage are properly backed up.

## Running the Containers

Running the containers with `docker-compose` is a no brainer. To accomplish that,
please do the following:

* Run -> ```docker-compose up```
  - The command above should be enough to build the images based on their respective
  docker files and download the images used for the SFTP and Minio servers.

Although you can also run on detached mode, I do recommend that the first run is
nicer without it. Why? Because you can follow up on all the green letters printed out
on your terminal. Besides that, if not enough, it's good to get acquainted with
the logs of the services, in case you have errors happening during startup.

* Run on detached mode -> ```docker-compose up -d```

### Accessing the Frontends

After starting the containers, you can access both JupyterLab, MLflow and Minio
in the following way:

1. JupyterLab: http://localhost:8888/lab
  - Copy the token printed out on the terminal to be able to access JupyterLab
2. MLflow: http://localhost:5500
3. Minio: http://localhost:9000

You will notice on the MLFow UI that only one experiment is available, the `Default` one.
The intention behind this exercise is to be able to use SFTP and Minio as storage.
Hence,  the `Default` experiment is not a good choice to make.

Let's explore other experiments.

### Creating Experiments on MLFow

To start with, we have to create the experiments in the MLflow server. But how to do it?
Easy: connect to the container and execute one command. Of course, once you are in
the container.

So, to start with, let's connect to the `ekholabs-mlflow`. To do that, run
the command below:

* ```docker exec -it ekholabs-mlflow /bin/bash```

If you type `mlflow --help` you will see a list of possible `commands` and `options`.

To create our experiments, which will use SFTP and Minio as storage server, just
execute the ```create_experiments.sh``` script.

I also advice you to have a look at the script to understand how the experiments are created.
If you face issues when running the script, please make sure the containers and running
and that the script is executable (`chmod +x create_experiments.sh`).

The script should be executed from the project root in the following way:

* Run -> ```./scripts/create_experiments.sh```

Now, if you go back to the MLflow frontend, you will see that two experiments have been created.

## How does the Communication Works

Before we get to the Jupyter notebooks, let's understand how the communication between
the services work and what we need to do to work around some issues of having it all locally.

If you take a look at the `docker-compose.yml` file, you will easily notice that the
`ekholabs-sftp` container has the `ssh_sftp_key.pub` file mounted as a volume. That
helps to ease communication with the SFTP server without using passwords. It also
means that the private key has to be added to the other containers that will have to
communicate with the SFTP server.

Hence, looking further into the `docker-compose.yml` file, you will notice that both
`ekholabs-mlflow` and `ekholabs-jupyterlab` have the `ssh_sftp_key` file mounted
as a volume. Along with that file, which is the private key, we also have a SSH `config`
file mounted as a volume.

Almost there... hang on.

Besides having both private key and SSH config files mounted on the volumes, we
need one last thing: the `ekholabs-sftp` has to be added to the `known_hosts`, which
goes under `~/.ssh/known_hosts` inside the containers.

Adding that extra information in the MLflow container is pretty easy. It comes with
OpenSHH installed, so just running the command below does the trick:

* ```ssh-keyscan -H ekholabs-sftp >> ~/.ssh/known_hosts```

**Please, do not execute the line above**, this command is already part of the `docker-compose.yml`,
which means that the host will be added to the `known_hosts` file of the MLflow container
automatically at start-up.

However, when it comes to the JupyterLab container, we do have an issue: it does not
contain the OpenSHH packaged and we are not allowed to install it. Hence, `ssh-keyscan`
won't work.

What's the problem with that? Well, when the notebook tries to log the artefact on the
tracking server (MLflow), `pysftp/Paramiko` will complain and throw and exception saying:
*No hosts for key!*

So, it can only mean one thing: we have to get the `known_hosts` from the `ekholabs-mlflow`
container into the `ekholabs-jupyterlab` container. But how? Well, with **Docker**! I mean,
with a shell script that will run some commands in the Docker containers.

Take a peak inside the ```copy_known_hosts.sh``` shell script to understand what it's doing.
Once you done, please execute that script from the root directory of the project.

* Run --> ```./scripts/copy_known_hosts.sh```

Now you are - almost - good to go!

**P.S.**: are you better than me at Docker sheiße? Please, contribute to this repo
and get rid of so many steps. :)

## We need a Bucket

*Well, completely unrelated, but I have a friend called Leonardo Bucket. Every time
I do something with S3 and have to say or write the word `bucket`, it reminds me of him. :D*

So, if we want to use Minio as storage, we do need a bucket. And, more over, the bucket
has to be created before we try to store artefacts.

If you have looked inside the ```create_experiments.sh```, you might have noticed that
we expect a bucket called ```ai-models```, not *Leonardo*, there.

To create a bucket, just go to Minio (http://localhost:9000) and the rest you should know.

Ah!, do you need a *key id* and *secret* combination to login? Have a ```docker-compose.yml```
file, the Minio key id / secret pair is informed there.

Done with the bucket? If so, now you are good to go. ;)

## Logging Metrics and Artefacts

There is not much to say here. To actually see how it's done, go to your JupyterLab
frontend and open the `conv-net-in-keras.ipynb` notebook. The last cell contains all
the magic you need.

## SSH Keys

This repository already contains the SSH keys that should be used to communicate with
the SFTP service, from both MLflow and Jupyter notebooks perspective.

If this setup is used to deploy a SFTP server for multiple users, with different
SSH keys presumably, then the following information from the sub-session bellow
has to be taken into account.

### Paramiko vs OpenSHH

Keys generated on MacBooks work when connecting to the SFTP server using the `sftp`
command from the shell. However, when the connection is established from within Jupyter
the `pysftp` library is used, which uses `Paramiko` under the hood. And that brings issues!

Do not waste your time googling a solution, trust me. The easiest / quickest thing
to do is generate your keys on a Linux machine / Docker container. The key files
under the `keys` directory have been created on a Docker container.

## WIP

This is working in progress and more about MLflow features, like service models,
will be added soon.
