#!/bin/sh
set -ex

dart install dart_pre_commit
echo "#!/bin/sh" > .git/hooks/pre-commit
echo "dart_pre_commit" >> .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
