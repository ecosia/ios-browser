always consider this codebase is mixed with firefox-ios and our modifications

write comprehensive tests

keep `firefox-ios/Ecosia/Ecosia.docc/Ecosia.md` up to date

don't update the `/README.md` file as it is part of the `firefox-ios` core

name pull requests "[MOB-XXXX] {name of the feature}"
[MOB-XXXX] is the ticket reference, it should be provided as part of the PR/Ticket/Instructions
also add MOB-XXXX with the correct ticket name into the branch name so we can link tickets and branches and pull requests by this identifier
issues that don't reference a ticket should use `NOTICKET` in the PR name and `noticket` in the branch name


consider a architecture descision record based on this template
https://github.com/joelparkerhenderson/architecture-decision-record/tree/main/locales/en/templates/decision-record-template-of-the-madr-project is a good template
request other considerations that to implement a feature
document unsolved issues in the architecture decision record
ADRs should be stored in  `docs/decisions/` and the readme `docs/decisions/README.md` should be updated to have an up to date list
`docs/decisions/0001-swiftlint-configuration-for-upstream-fork.md` is a good name for the ADR

consider adding readme.md files into folders that are created or touched heavily during feature development so that folders represent features and have some documentation
