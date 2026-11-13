# Contributing to KubixTestBench

Thank you for your interest in contributing to **KubixIntegration**! 

---

## Table of Contents
- [Getting Started](#getting-started)
- [Branch Naming Convention](#branch-naming-convention)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Requirements](#pull-request-requirements)
---

## Getting Started

1. **Check existing issues:** Before starting work on a new feature or bug fix, check the [Issues](../../issues) tab to see if someone is already working on it. If not, feel free to open a new issue to discuss your idea!
2. **Fork the repository:** Click the "Fork" button at the top right of this page.

## Branch Naming Convention
Please keep branch names clear, lowercase, and separated by hyphens:
- New features: feature/short-description (e.g., feature/nes-cpu-connection)
- Bug fixes: bugfix/short-description (e.g., bugfix/slow-frame-rate)
- Documentation: docs/short-description (e.g., docs/new-device-added)

## Commit Message Guidelines
We follow Conventional Commits to keep the git history readable and organized. Please prefix your commit messages with one of the following types:
- feat: A new feature or implementation
- fix #[issue number]: A bug fix (If the commit solves a existent issue, add the issue number to it)
- docs: Documentation changes only
- refactor: Code changes that neither fix a bug nor add a feature
- test: Adding or updating tests
Example: `feat: implement dual-port memory simulation for video output`

## Pull Request Requirements
When submitting a Pull Request (PR), please target the main (or develop) branch and include the following proof of work in your PR description:
- New Implementation (from scratch):
    You must attach a video or GIF demonstrating and testing the new feature on physical hardware.
- Enhancement or Bug Fix:
    Attach a video/GIF if the change is visual, or provide some console log test / test output proving that the code compiles and runs without errors.
- Link the Issue:
    If your PR resolves an open issue, include Closes #<issue_number> in the description and in the commit.
