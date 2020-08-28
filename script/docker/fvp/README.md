
Copyright (c) 2020, Arm Limited. All rights reserved.

SPDX-License-Identifier: BSD-3-Clause


LAVA FVP containers
==============

Scripts that create dockerfile/dockerimages with FVP models installed to be consumed by a FVP LAVA device.

Build
=====

Fetch any FVP model from [ARM sites][2][4] and either place the tarballs either inside current project and
type `make`. This will create new docker images.

For example, lets assume that we download the model `FVP_Base_Cortex-A35x124_11.11_34.tgz` and store at current
directory as seen below:

```bash
ls -la
total 46858
drwxrwxr-x   3 lsandov1       lsandov1     4096 2020-08-28 13:33 .
drwxrwxr-x   9 lsandov1       lsandov1     4096 2020-08-28 13:13 ..
-rw-rw-r--   1 lsandov1       lsandov1 47966029 2020-08-28 13:29 FVP_Base_Cortex-A35x124_11.11_34.tgz
-rw-rw-r--   1 lsandov1       lsandov1      540 2020-07-03 11:49 Makefile
-rw-rw-r--   1 lsandov1       lsandov1     2405 2020-08-28 13:32 README.md
-rwxrwxr-x   1 lsandov1       lsandov1      691 2020-07-03 11:36 create_fvp_dockerfile.sh
-rw-rw-r--   1 lsandov1       lsandov1      753 2020-08-05 22:21 dockerfile-template
-rwxrwxr-x   1 lsandov1       lsandov1      171 2020-07-03 10:56 tag.sh
drwxrwxr-x   3 lsandov1       lsandov1     4096 2020-08-28 13:33 ws
```

then execute `make`

```bash
make
base=FVP_Base_Cortex-A35x124_11.11_34.tgz && \
tag=fvp_base_cortex-a35x124_11.11_34 && \
mkdir -p ws/${tag} && \
cp FVP_Base_Cortex-A35x124_11.11_34.tgz ws/${tag} && \
./create_fvp_dockerfile.sh ws/${tag} ${base} && \
docker build --tag fvp:${tag} ws/${tag}/
Sending build context to Docker daemon  47.97MB
Step 1/6 : FROM ubuntu:bionic
 ---> 6526a1858e5d
Step 2/6 : RUN apt-get update &&     apt-get install --no-install-recommends --yes bc libatomic1 telnet libdbus-1-3 xterm &&     rm -rf /var/cache/apt
 ---> Using cache
 ---> 822600bee149
Step 3/6 : RUN mkdir /opt/model
 ---> Using cache
 ---> 58db835c0b3c
Step 4/6 : ADD FVP_Base_Cortex-A35x124_11.11_34.tgz /opt/model
 ---> Using cache
 ---> bb634f5def64
Step 5/6 : RUN cd /opt/model &&     /opt/model/FVP_Base_Cortex-A35x124.sh         --i-agree-to-the-contained-eula         --verbose         --destination /opt/model/FVP_Base_Cortex-A35x124
 ---> Using cache
 ---> 49989d166049
Step 6/6 : WORKDIR /fvp
 ---> Using cache
 ---> cc3a4494599a
Successfully built cc3a4494599a
Successfully tagged fvp:fvp_base_cortex-a35x124_11.11_34
~/repos/tf/dockerfiles/fvp $
```

as seen in the log above, a new docker image has been created `fvp:fvp_base_cortex-a35x124_11.11_34`.
In case you want to see the `Dockerfile` for this particular model, check the following directory
`$PWD/ws/fvp_base_cortex-a35x124_11.11_34/Dockerfile`

Rerefence dockerfile
====================

The [dockerfile](./dockerfile-template) use on this project is similar to the [reference dockerfile][1]
but the former also installs the model. The reason to this extra step is that [LAVA][3] expects the
container with the model installed.


[1]: https://validation.linaro.org/static/docs/v2/fvp.html?highlight=fvp
[2]: https://developer.arm.com/tools-and-software/simulation-models/fixed-virtual-platforms
[3]: https://git.lavasoftware.org/lava/lava
[4]: https://silver.arm.com/browse/FM000
