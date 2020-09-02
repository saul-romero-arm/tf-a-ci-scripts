#!/usr/bin/env python3
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Script that takes a FVP yaml file and produces  the parameters for a docker run
# command. Conceptually, this is similar to 'pgk-config' system application but
# this scripts applies to docker-run parameters.
#
# To exemplify its usage, let's assume we have the a FVP yaml file at ~/fvp.yaml
# then launch the container using the script to provide the correct model parameters
#
#    $ docker run `./yaml-docker-config ~/fvp.yaml`
#
# If no errors, the (containerized) FVP model should be up and running. In case the
# docker image is not found, please create one following the instructions on the
# fvp/README.md file.

import yaml, sys, os.path, argparse

class YamlDockerConfig:
    def __init__(self, yaml_file):
        with open(yaml_file) as f:
                self.data = yaml.load(f, Loader=yaml.FullLoader)

        self.docker_image = self. data['actions'][1]['boot']['docker']['name']
        self.image = self. data['actions'][1]['boot']['image']
        self.params =  self.data['actions'][1]['boot']['arguments']

        self._artefacts = self.data['actions'][0]['deploy']['images']
        self.artefacts = [(self._artefacts[a]['url'], os.path.basename(self._artefacts[a]['url'])) for a in self._artefacts.keys()]

    def docker_params(self):
        docker_image, docker_ep = f"{self.docker_image}", f"{self.image}"
        docker_bn_ep = os.path.dirname(docker_ep)
        model_params = f"{' '.join(self.params)}"

        # each artefact correspond to a --volume parameter
        volumes = ''
        for artefact in self.artefacts:
            if artefact[0]:
                a = artefact[0].strip('file:')
                volumes += f"--volume {a}:{docker_bn_ep}/{artefact[1]} "

        self._docker_params = volumes + " " + docker_image + " " + docker_ep + " " + model_params
        return self._docker_params

if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("yaml", help="yaml filepath")
    opts = parser.parse_args()

    ydc = YamlDockerConfig(opts.yaml)
    print(ydc.docker_params())

    sys.exit(0)
