# Contributing

Thank you for your interest in contributing to this repository! Before making any changes, please reach out to the repository owner to discuss your proposed changes. You can do this by creating an issue, emailing the owner, or using any other preferred method of communication.

## Built With

![Python Badge](https://img.shields.io/badge/Python-FFD43B?style=for-the-badge&logo=python&logoColor=blue)

## Pre-Commit

This repository utilizes pre-commit functionalities, specifically **Ruff**. Ensure these tools are configured and installed on your machine.

## Installation

We track dependencies and other stuff via [uv](https://docs.astral.sh/uv/) file. To install the required items, run the following commands:

```bash
pip install uv
uv python install 3.12 #Make sure you have a correct python version installed  
uv sync --no-cache
```

## Formatting

This repository uses **Ruff** as the source code formatter. The formatting tools are configured as a pre-commit hook. Please run the following command during your first commit to set it up:

```bash
pre-commit install
```

## Branch Protection

As the repository grows in importance, make sure to configure branch protection rules that run code analysis on each pull request to maintain code quality.

Default branch protection rules are configured on the organization level for the main branch.