#!/usr/bin/env bash
set -o errexit

pip install --only-binary :all: -r requirements.txt
