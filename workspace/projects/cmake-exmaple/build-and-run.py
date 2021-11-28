#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import logging
import subprocess


class Project:
    def __init__(self, name, description):
        self.name = name
        self.description = description

    def header(self):
        return '✨ {}: {} ✨'.format(self.name, self.description)

    def clean(self):
        logger.info("🧹 Cleaning output folders...")

    def setup(self):
        logger.info("⚙ Initialising git submodules...")
        cp = subprocess.run(
            [
                "rm -rf build/* .local/bin/* .local/include/* .local/lib/* .local/test/*"
            ],
            shell=True,
            #                            universal_newlines=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
        logger.debug(cp.stdout)
        logger.debug(cp.stderr)
        logger.debug(cp.returncode)


logger = logging.getLogger('builder')


def main():
    logging.basicConfig()
    logger.setLevel(logging.DEBUG)

    project = Project("MyProject", "A CMake Project Template with Tests")
    logger.info(project.header())
    project.clean()
    project.setup()


if __name__ == "__main__":
    main()
