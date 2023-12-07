#!/bin/bash
set -e

npm install -g typescript

echo "" >> $HOME/.bashrc
echo 'source <(just --completions bash)' >> $HOME/.bashrc
echo "" >> $HOME/.bashrc

(cd src/batcher && npm install)
pip install -r src/batch_receiver/requirements.txt
