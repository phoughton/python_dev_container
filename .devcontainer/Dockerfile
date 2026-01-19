FROM mcr.microsoft.com/devcontainers/python:3.12-bookworm


RUN echo 'alias ll="ls -lrta"'  >> ~vscode/.bashrc

RUN apt update && \
    apt install -y hexyl && \ 
    apt install -y sysvbanner && \
    apt install -y ttyrec

RUN echo "banner 'Hello'" >>  ~vscode/.bashrc && \
    echo "date\necho 'Installed:'\n echo ' - hexyl'\necho ' - banner'\necho ' - ttyrec'" >> ~vscode/.bashrc 