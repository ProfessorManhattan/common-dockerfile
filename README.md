# Dockerfile Project Common Files

This repository includes common files that are shared throughout [our various Dockerfile repositories](https://gitlab.com/megabyte-labs/dockerfile). It is used in conjunction with the `.start.sh` file that is present in all our Dockerfile projects. The `.start.sh` file synchronizes various files from this repository.

In one of our Dockerfile repositories, you can run the following to synchronize with the upstream repositories:

```
bash .start.sh
```
